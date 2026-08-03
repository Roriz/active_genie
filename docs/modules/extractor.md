# Extractor

Turns unstructured text into typed, structured data using a schema you define.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models, so expect the same shape with different values.

## How it works

You describe the fields you want. `Extractor` asks the model to fill them, constrained to the types you declared.

It has three strategies:

- Explanation, the default, extracts each field *and* asks the model to justify it and rate its own confidence. The justifications land in `metadata`, so you can see why the model returned a given value.
- Data extracts the fields only. That is one less thing for the model to generate, so it's cheaper and faster, but it leaves no audit trail.
- Litote handles understatement. "Not bad at all" means good, and a naive extraction reads the negative and gets it backwards.

## Basic usage

```ruby
text = "Sony 65\" Class BRAVIA XR X95K 4K HDR Mini LED TV - $1999.99 (Save $500)"

schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  price: { type: 'number', minimum: 0, description: 'Current price' },
  discount: { type: 'number', minimum: 0, description: 'Amount saved' }
}

result = ActiveGenie::Extractor.call(text, schema)

result.data
# => { brand: "Sony", display_size: "65\"", price: 1999.99, discount: 500.0 }
```

## Interface

### `.call(text, data_to_extract, config: {})`

Extracts with explanations. Alias for `.with_explanation`.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `text` | String | The text to extract from. |
| `data_to_extract` | Hash | Schema describing the fields. See [Schemas](#schemas). |
| `config` | Hash | Per-call configuration overrides. See [Configuration](/reference/config). |

### `.with_explanation(text, data_to_extract, config: {})`

Identical to `.call`. Use it when you want the strategy named explicitly at the call site.

### `.data(text, data_to_extract, config: {})`

Extracts the fields without the explanation pass, which costs less and runs faster.

```ruby
result = ActiveGenie::Extractor.data(text, schema)

result.data
# => { "brand" => "Sony", "price" => 1999.99 }

result.reasoning
# => nil
```

> [!WARNING]
> `.data` returns **string** keys and a `nil` reasoning; `.call` returns **symbol** keys and populated reasoning. Swapping one for the other will silently break key access:
>
> ```ruby
> ActiveGenie::Extractor.call(text, schema).data[:brand]  # => "Sony"
> ActiveGenie::Extractor.data(text, schema).data[:brand]  # => nil
> ActiveGenie::Extractor.data(text, schema).data['brand'] # => "Sony"
> ```
>
> Normalize with `transform_keys(&:to_sym)` if you need to switch between them.

The two strategies can also disagree on the extraction itself. Requiring the model to justify a field tends to tighten it. Extracting `brand` from `"Nike Air Max 90 - Size 42 - $199.99"`:

```ruby
ActiveGenie::Extractor.call(text, schema).data[:brand]  # => "Nike"
ActiveGenie::Extractor.data(text, schema).data['brand'] # => "Nike Air Max 90"
```

When precision matters more than cost, prefer `.call`.

### `.with_litote(text, data_to_extract, config: {})`

Detects understatement and extracts from the plain meaning instead of the literal words.

```ruby
review = "The new update isn't terrible, but it's not exactly amazing either"

schema = {
  sentiment: { type: 'string', enum: %w[positive negative neutral mixed] },
  satisfaction_level: { type: 'integer', minimum: 1, maximum: 5 }
}

result = ActiveGenie::Extractor.with_litote(review, schema)

result.data
# => { sentiment: "mixed", satisfaction_level: 3 }
```

This runs in two passes. The first extracts your fields alongside `message_litote` and `litote_rephrased`. If a litote was detected, it rephrases the text plainly and extracts your fields again from the rephrasing.

> [!IMPORTANT]
> The two outcomes return different keys:
>
> - When a litote is detected, a second extraction runs against your original schema, so `data` contains **only your fields**. `message_litote` and `litote_rephrased` are not present.
> - When no litote is detected, `data` contains your fields **plus** `message_litote: false` and `litote_rephrased`.
>
> Use `result.data.fetch(:message_litote, true)` rather than assuming the key exists.

## Return value

Returns an [`ActiveGenie::Result`](/introduction/quickstart#understanding-activegenie-result).

| Strategy | `data` keys | `data` contents | `reasoning` |
| :--- | :--- | :--- | :--- |
| `.call` / `.with_explanation` | Symbols | Your schema fields only | The first field's explanation |
| `.data` | Strings | The provider response, compacted | `nil` |
| `.with_litote` | Symbols | Your schema fields, plus litote fields only when no litote was found | The first field's explanation |

> [!IMPORTANT]
> The `*_explanation` and `*_accuracy` fields are **not** in `data`. They are in `metadata`.

```ruby
result = ActiveGenie::Extractor.call("Nike Air Max 90 - Size 42 - $199.99",
                                     { brand: { type: 'string' }, price: { type: 'number' } })

result.data
# => { brand: "Nike", price: 199.99 }

result.metadata
# => {
#      "brand" => "Nike",
#      "brand_explanation" => "Brand name at the start of the product title",
#      "brand_accuracy" => 100,
#      "price" => 199.99,
#      "price_explanation" => "Price in USD at the end of the string",
#      "price_accuracy" => 100
#    }
```

`*_accuracy` is the model's own confidence on a 0-100 scale. A 100 means the value was stated explicitly in the text, and a 0 means the model could not determine it.

## Schemas

A schema is a hash of field names to descriptors.

| Key | Purpose |
| :--- | :--- |
| `type` | `'string'`, `'number'`, `'integer'`, `'boolean'`, `'array'`, `'object'` |
| `description` | What the field means. Nothing else in the schema affects extraction quality as much. |
| `enum` | Restricts the value to a fixed set. |
| `minimum` / `maximum` | Numeric bounds. |
| `items` | Element descriptor for `array` types. |

```ruby
schema = {
  sentiment: {
    type: 'string',
    enum: %w[positive negative neutral],
    description: 'Overall tone of the message'
  },
  rating: {
    type: 'integer',
    minimum: 1,
    maximum: 5,
    description: 'Star rating, if one is stated'
  },
  tags: {
    type: 'array',
    items: { type: 'string' },
    description: 'Topics mentioned'
  }
}
```

## Configuration

| Setting | Default | Description |
| :--- | :--- | :--- |
| `config.extractor.min_accuracy` | `70` | Intended confidence floor for a field. |

> [!WARNING]
> `min_accuracy` is **not currently enforced**. The `*_accuracy` values are returned in `metadata` but nothing is filtered against this threshold. Apply it yourself if you need it:
>
> ```ruby
> result = ActiveGenie::Extractor.call(text, schema)
> trusted = result.data.reject { |k, _| result.metadata["#{k}_accuracy"].to_i < 70 }
> ```

`Extractor` is tuned against `deepseek-chat` across all three strategies. See [Configuration](/reference/config) for the full set of options and [Observability & errors](/reference/observability) for failure handling.

## Cost

| Strategy | LLM calls | Relative output size |
| :--- | :--- | :--- |
| `.data` | 1 | Smallest |
| `.call` / `.with_explanation` | 1 | Larger: three fields generated per schema field |
| `.with_litote` | 1 or 2 | Second call only when a litote is detected |

The explanation pass roughly triples the generated tokens, since every field produces a value, an explanation, and an accuracy score. Use `.data` for high-volume extraction where you won't inspect the reasoning.

## Tips

- Descriptions matter more than types. `description: 'Screen size with units'` is what makes the model return `"65\""` rather than `65`. Write them for a human who has never seen your data.
- Use `enum` whenever the value set is known. It turns an open-ended generation into a classification, which is more reliable.
- Ask for what's in the text. The model guesses at fields that require inference, so check `*_accuracy` for anything not stated explicitly.
- Prefer `string` for anything with units or formatting. Sizes, phone numbers, and SKUs lose information when coerced to numbers.
- Reach for `.with_litote` on human-written opinion such as reviews, feedback, and chat messages. Skip it for structured product data, where it only adds a possible second call.
- Normalize keys at the boundary. If your code path may use either `.call` or `.data`, symbolize once on the way out.

## Examples

### Support ticket triage

```ruby
schema = {
  category: { type: 'string', enum: %w[billing technical account feature_request] },
  urgency: { type: 'string', enum: %w[low medium high critical] },
  summary: { type: 'string', description: 'One-sentence restatement of the problem' }
}

ActiveGenie::Extractor.call(ticket_body, schema)
```

### Review sentiment with understatement

```ruby
schema = {
  overall_rating: { type: 'integer', minimum: 1, maximum: 5 },
  recommendation: { type: 'boolean', description: 'Would the reviewer recommend it?' }
}

ActiveGenie::Extractor.with_litote(
  "This restaurant isn't bad at all. The service wasn't horrible either.",
  schema
)
# => { overall_rating: 4, recommendation: true }
```

### High-volume product parsing

```ruby
schema = {
  brand: { type: 'string' },
  price: { type: 'number', minimum: 0 }
}

listings.map do |listing|
  ActiveGenie::Extractor.data(listing, schema).data.transform_keys(&:to_sym)
end
```

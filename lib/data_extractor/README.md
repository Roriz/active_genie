# Data Extractor
Extract structured data from text using LLM-powered analysis, handling informal language and complex expressions.

## ✨ Features
- Simple extraction   - Extract structured data from unstructured text
- Informal extraction - Identifies and handles informal language patterns

## Basic Usage

Extract structured data from text using predefined schemas:

```ruby
text = "iPhone 14 Pro Max"
schema = {
  brand: { type: 'string' },
  model: { type: 'string' }
}
result = ActiveAI::DataExtractor.call(text, schema)
# => { brand: "iPhone", model: "14 Pro Max" }

product = "Nike Air Max 90 - Size 42 - $199.99"
schema = {
  brand: { 
    type: 'string',
    enum: ["Nike", "Adidas", "Puma"]
  },
  price: { 
    type: 'number',
    minimum: 0
  },
  currency: { 
    type: 'string',
    enum: ["USD", "EUR"]
  },
  size: {
    type: 'integer',
    minimum: 35,
    maximum: 46
  }
}

result = ActiveAI::DataExtractor.call(product, schema)
# => { brand: "Nike", price: 199.99, size: 42, currency: "USD" }
```

## Informal Text Processing

The `from_informal` method helps extract structured data from casual, conversational text by interpreting common informal expressions and linguistic patterns like:

- Affirmative expressions ("sure", "no problem", "you bet")
- Negative expressions ("nah", "not really", "pass")
- Hedging ("maybe", "I guess", "probably")
- Litotes ("not bad", "not the worst")

### Example

```ruby
text = <<~TEXT
  system: Would you like to proceed with the installation?
  user: not bad
TEXT

data_to_extract = {
  user_consent: { type: 'boolean' }
}

result = ActiveAI::DataExtractor.from_informal(text, data_to_extract)
puts result # => { user_consent: true }
```

### Usage Notes
- Best suited for processing conversational user inputs
- Handles ambiguous or indirect responses
- Useful for chatbots and conversational interfaces
- May require more processing time and tokens
- Accuracy depends on context clarity

⚠️ Performance Impact: This method uses additional language processing, which can increase token usage and processing time. 

## Interface
`.call(text, data_to_extract, options = {})`
Extracts structured data from text based on a schema.

### Parameters
| Name | Type | Description | Required | Example | Default |
| --- | --- | --- | --- | --- | --- |
| `text` | `String` | The text to extract data from. Max 1000 chars. | Yes | "These Nike shoes are red" | - |
| `data_to_extract` | `Hash` | [JSON Schema object](https://json-schema.org/understanding-json-schema/reference/object) defining data structure | Yes | `{ category: { type: 'string', enum: ["shoes"] } }` | - |
| `options` | `Hash` | Additional provider configuration options | No | `{ model: "gpt-4" }` | `{}` |

### Returns
`Hash` - Dynamic hash based on the `data_to_extract` schema.

### Options
| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `model` | `String` | The model name | `YAML.load_file(config_file).first.model` |
| `api_key` | `String` | The API key to use or api_key from model on config.yml | `YAML.load_file(config_file).first.api_key` |

⚠️ Performance Considerations
- Processes may require multiple LLM calls
- Expect ~100 tokens per request + the text from input
- Consider background processing for production use

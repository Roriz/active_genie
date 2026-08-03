# Quickstart

ActiveGenie has five modules. They all return the same object, and they all run against any supported provider. Each section below has a working example and a note on what you get back.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and between models, so expect the same shape with different values.

Every example assumes a credentialed provider. See [Installation](/introduction/installation) if you haven't set one up.

## Extractor

The extractor turns unstructured text into typed data.

```ruby
text = "Sony 65\" BRAVIA XR - $1999.99 (Save $500!) Amazing 4K HDR quality"

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

The default strategy also records why it picked each field, under `metadata`:

```ruby
result.metadata['price_explanation']
# => "Price in USD following the product name"
result.metadata['price_accuracy']
# => 100
```

If you don't need those explanations, use `.data` instead of `.call` for a cheaper request. It returns string keys rather than symbols:

```ruby
ActiveGenie::Extractor.data(text, schema).data
# => { "brand" => "Sony", "price" => 1999.99 }
```

For text that uses understatement, `.with_litote` rephrases before extracting:

```ruby
ActiveGenie::Extractor.with_litote(
  "The new update isn't terrible, but it's not exactly amazing either",
  { sentiment: { type: 'string', enum: %w[positive negative neutral mixed] } }
).data
# => { sentiment: "mixed" }
```

[Full documentation →](/modules/extractor)

## Scorer

The scorer rates text from 0 to 100. It assembles a jury of domain experts that fit the content.

```ruby
code_review = "Added rate limiting with a sliding window algorithm, including unit tests and performance benchmarks"
criteria = "Evaluate technical quality, completeness, and engineering best practices"

result = ActiveGenie::Scorer.call(code_review, criteria)

result.data
# => 91

result.reasoning
# => "All reviewers rate the implementation highly, citing the algorithm choice
#     and the presence of both tests and benchmarks."
```

`data` is the score itself. The per-jury breakdown is in `metadata`:

```ruby
result.metadata
# => {
#      "senior_software_engineer_score" => 94,
#      "senior_software_engineer_reasoning" => "Appropriate algorithm, well tested.",
#      "technical_architect_score" => 89,
#      "technical_architect_reasoning" => "Sound approach; document the strategy.",
#      "final_score" => 91,
#      "final_reasoning" => "..."
#    }
```

Supply your own juries to halve the cost and get stable keys:

```ruby
ActiveGenie::Scorer.call(medical_text, criteria, ["Cardiologist", "Medical Writer"])
```

[Full documentation →](/modules/scorer)

## Comparator

The comparator picks a winner between two options.

```ruby
player_a = "Implementation uses dependency injection, enabling easy testing and component replacement"
player_b = "Code achieves 95% test coverage using traditional patterns with proven stability"
criteria = "Evaluate long-term maintainability, testability, and team productivity"

result = ActiveGenie::Comparator.call(player_a, player_b, criteria)

result.data
# => "Implementation uses dependency injection, enabling easy testing and component replacement"
```

`data` is the winning input, returned exactly as you passed it. The result has no `loser` key, so work it out yourself:

```ruby
winner = result.data
loser  = (winner == player_a ? player_b : player_a)
```

`.by_fight` is a variant tuned for combat scenarios:

```ruby
ActiveGenie::Comparator.by_fight(
  "Master Crane: graceful, precise, redirects momentum",
  "Iron Ox: overwhelming strength and mass",
  "Who wins a one-on-one duel?"
)
```

[Full documentation →](/modules/comparator)

## Lister

The lister generates an ordered list for a theme, sorted by how commonly people would name each item.

```ruby
result = ActiveGenie::Lister.call("Features smartphone users care about most")

result.data
# => ["Battery life", "Camera quality", "Price", "Storage capacity", "Brand reputation"]
```

Set how many items you want:

```ruby
ActiveGenie::Lister.call("Most popular breakfast foods worldwide",
  config: { lister: { number_of_items: 10 } })
```

`.with_juries` returns expert roles rather than survey answers:

```ruby
ActiveGenie::Lister.with_juries(
  "Technical proposal for a microservices migration",
  "Assess technical feasibility and business impact"
).data
# => ["Software Architect", "DevOps Engineer", "Business Analyst"]
```

[Full documentation →](/modules/lister)

## Ranker

The ranker orders a list best first, using scoring, elimination, and head-to-head debates.

```ruby
api_options = [
  "REST API with comprehensive OpenAPI documentation and versioning",
  "GraphQL API with efficient query resolution and real-time subscriptions",
  "gRPC API with Protocol Buffers and bi-directional streaming",
  "WebSocket API with a custom protocol and connection state management"
]

result = ActiveGenie::Ranker.call(api_options, "Best fit for a real-time collaborative application")

result.data
# => [
#      "GraphQL API with efficient query resolution and real-time subscriptions",
#      "WebSocket API with a custom protocol and connection state management",
#      "gRPC API with Protocol Buffers and bi-directional streaming",
#      "REST API with comprehensive OpenAPI documentation and versioning"
#    ]
```

`data` is your items reordered, so rank is positional. Scores and ELO ratings live in `metadata`.

> [!WARNING]
> `Ranker` is expensive. Its final stage debates every surviving pair, so cost grows quadratically: 4 items is 6 debates, 30 items is 435. Read [Cost](/modules/ranker#cost) before ranking large lists.

[Full documentation →](/modules/ranker)

## Understanding ActiveGenie::Result

Every module returns an `ActiveGenie::Result` with the same three accessors.

| Accessor | Contents |
| :--- | :--- |
| `data` | The answer. Its type depends on the module (see the table below). |
| `reasoning` | Why the module produced that answer. Aliased as `explanation`. |
| `metadata` | The full underlying response, useful for debugging and auditing. String keys. |

`data` is deliberately narrow. It holds the single thing you asked for rather than a wrapper around it:

| Call | `data` type | `data` value |
| :--- | :--- | :--- |
| `Extractor.call` | Hash (symbol keys) | The extracted fields |
| `Extractor.data` | Hash (string keys) | The extracted fields |
| `Scorer.call` | Numeric | The final score, 0 to 100 |
| `Comparator.call` | String or Hash | The winning input |
| `Lister.call` | Array&lt;String&gt; | The list, most common first |
| `Ranker.call` | Array | Your items, best first |

```ruby
result.to_h    # => { data: ..., reasoning: "...", metadata: {...} }
result.to_json # => "{\"data\":...}"
```

> [!TIP]
> Build on `data` and `reasoning`. Treat `metadata` as debugging output, since its keys follow the prompts and can change between versions.

## Switching providers

The `config:` keyword overrides configuration for a single call. Its keys are nested by section:

```ruby
# Pick a model. The provider is inferred from the model name.
ActiveGenie::Extractor.call(text, schema, config: { llm: { model: 'deepseek-chat' } })

# Or name the provider and take its default model.
ActiveGenie::Scorer.call(text, criteria, config: { providers: { default: 'anthropic' } })
```

> [!WARNING]
> ActiveGenie silently ignores top-level keys. It raises no error, and the setting simply never applies.
>
> ```ruby
> config: { model: 'deepseek-chat' }          # ignored
> config: { llm: { model: 'deepseek-chat' } } # correct
> ```

The same call works against any provider:

```ruby
%w[gpt-4o-mini claude-haiku-4-5 deepseek-chat gemini-3.5-flash-lite].each do |model|
  ActiveGenie::Comparator.call(player_a, player_b, criteria, config: { llm: { model: model } })
end
```

See [Configuration](/reference/config) for every available option.

## Testing your code

ActiveGenie calls real provider APIs. In your own test suite you almost never want that. Real calls are slow and cost money, and they return something different on every run.

Stub at the provider boundary, `ActiveGenie::Providers::UnifiedProvider.function_calling`. Everything above it still runs (schema construction, response formatting, the `Result` wrapper), so you test your own integration rather than the model.

Your stub returns the raw provider response, which is a hash with string keys.

```ruby
# Minitest
ActiveGenie::Providers::UnifiedProvider.stub(
  :function_calling,
  { "brand" => "Nike", "brand_explanation" => "stated", "brand_accuracy" => 100 }
) do
  result = ActiveGenie::Extractor.call("Nike Air Max", { brand: { type: 'string' } })
  assert_equal({ brand: "Nike" }, result.data)
end
```

```ruby
# RSpec
allow(ActiveGenie::Providers::UnifiedProvider).to receive(:function_calling)
  .and_return({ "final_score" => 85, "final_reasoning" => "Solid." })

expect(ActiveGenie::Scorer.call(text, criteria).data).to eq(85)
```

Two things to keep in mind:

- Match the real response shape. Each strategy pulls specific keys out of it: `Scorer` reads `final_score`, `Lister` reads `items`, and `Comparator` reads `impartial_judge_winner`. A stub that omits them produces `nil` data.
- Silence logging in tests so provider events stay out of your test output:

  ```ruby
  ActiveGenie.configure { |c| c.log.output = ->(_log) {} }
  ```

For coverage against live providers, see how ActiveGenie tests itself in the [benchmark](/benchmark/latest).

## Next steps

- [Extractor](/modules/extractor): schemas, litotes, and extraction strategies
- [Scorer](/modules/scorer): juries, thresholds, and evaluation
- [Comparator](/modules/comparator): debates and fight mode
- [Lister](/modules/lister): surveys and jury selection
- [Ranker](/modules/ranker): tournaments, ELO, and cost control
- [Configuration](/reference/config): providers, models, retries, concurrency

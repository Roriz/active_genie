# Configuration

ActiveGenie reads its settings from a single configuration object. You can set it once globally, or override any part of it for an individual call.

## Two ways to configure

### Global

Set defaults once, at boot:

```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.llm.model = 'gpt-4o-mini'
end
```

### Per call

Every module method accepts a `config:` keyword. ActiveGenie deep-merges it over the global configuration for that call only, and the global settings stay untouched:

```ruby
ActiveGenie::Extractor.call(text, schema, config: { llm: { model: 'deepseek-chat' } })
```

> [!WARNING]
> The `config:` hash is nested by section, matching the structure of the global configuration. ActiveGenie ignores keys placed at the top level. It raises no exception, and the setting never applies.
>
> ```ruby
> # Ignored. Does nothing.
> config: { model: 'deepseek-chat' }
> config: { provider_name: :deepseek }
> config: { number_of_items: 10 }
>
> # Correct.
> config: { llm: { model: 'deepseek-chat' } }
> config: { providers: { default: 'deepseek' } }
> config: { lister: { number_of_items: 10 } }
> ```

The valid top-level sections are `providers`, `llm`, `log`, `ranker`, `extractor`, and `lister`. Each is described below.

## Providers (`config.providers`)

ActiveGenie ships with four providers: OpenAI, Anthropic, DeepSeek, and Google. It loads all four automatically, and each one reads its API key from the environment.

| Provider | Key | Environment variable | Default model | Default API URL |
| :--- | :--- | :--- | :--- | :--- |
| OpenAI | `:openai` | `OPENAI_API_KEY` | `gpt-4o-mini` | `https://api.openai.com/v1` |
| Anthropic | `:anthropic` | `ANTHROPIC_API_KEY` | `claude-haiku-4-5-20251001` | `https://api.anthropic.com` |
| DeepSeek | `:deepseek` | `DEEPSEEK_API_KEY` | `deepseek-chat` | `https://api.deepseek.com/v1` |
| Google | `:google` | `GENERATIVE_LANGUAGE_GOOGLE_API_KEY`, falling back to `GEMINI_API_KEY` | `gemini-3.5-flash-lite` | `https://generativelanguage.googleapis.com` |

### Choosing a provider

`config.providers.default` selects which provider to use when a call doesn't specify one. If you never set it, ActiveGenie uses the first provider that has a valid API key.

```ruby
ActiveGenie.configure do |config|
  config.providers.default = :anthropic
end
```

You usually don't need to set it. ActiveGenie resolves the provider from the model name: `gpt-*` maps to OpenAI, `claude-*` to Anthropic, `deepseek-*` to DeepSeek, and `gemini-*` to Google. Setting a model is enough:

```ruby
# Resolves to DeepSeek automatically.
ActiveGenie::Scorer.call(text, criteria, config: { llm: { model: 'deepseek-chat' } })
```

### Per-provider settings

| Setting | Type | Description |
| :--- | :--- | :--- |
| `api_key` | String | The provider's API key. Falls back to the environment variable in the table above. |
| `api_url` | String | Base URL for the API. Override to point at a proxy or compatible endpoint. |
| `default_model` | String | Model used when this provider is selected and no model is set. |
| `organization` | String | Organization identifier, where the provider supports one. |

Anthropic adds one more:

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `anthropic_version` | String | `'2023-06-01'` | Value sent in the `anthropic-version` header. |

```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.providers.anthropic.api_key = ENV['ANTHROPIC_API_KEY']
  config.providers.anthropic.anthropic_version = '2024-02-15'
  config.providers.deepseek.default_model = 'deepseek-reasoner'
end
```

### Methods

- `config.providers.add(name, provider_configs)` registers a custom provider configuration class.
- `config.providers.remove(provider_configs)` removes registered providers.
- `config.providers.valid` returns the providers that currently have a usable API key.
- `config.providers.provider_name_by_model(model)` returns the provider a given model name resolves to.

## Recommended models

Each module declares the model it was tuned against. ActiveGenie falls back to this when no model is configured and the module's preferred provider has credentials available.

| Module | Recommended model |
| :--- | :--- |
| `Extractor` (all strategies) | `deepseek-chat` |
| `Scorer` | `deepseek-chat` |
| `Comparator` | `claude-haiku-4-5-20251001` |
| `Lister.with_feud` | `claude-haiku-4-5-20251001` |
| `Lister.with_juries` | `deepseek-chat` |
| `Ranker` | inherits from `Scorer` and `Comparator`, which it composes |

These are defaults, not restrictions. Any model from any configured provider works. See the [benchmark](/benchmark/latest) for measured pass rates per provider.

## LLM (`config.llm`)

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `model` | String | `nil` | Model to use. When `nil`, resolution falls through the chain below. |
| `recommended_model` | String | set per module | The model a module was tuned against. Rarely set by hand. |
| `temperature` | Numeric | `0` | Sampling randomness. ActiveGenie defaults to `0` for reproducibility. |
| `max_tokens` | Integer | `4096` | Maximum tokens in the response. |
| `max_fibers` | Integer | `10` | Maximum concurrent in-flight requests. See [Concurrency](#concurrency). |
| `max_retries` | Integer | `nil` | Retry attempts for a failed request. |
| `retry_delay` | Numeric | `nil` | Seconds between retries. |
| `read_timeout` | Numeric | `nil` | Seconds to wait for a response body. |
| `open_timeout` | Numeric | `nil` | Seconds to wait for a connection. |

`provider_name` is readable but not writable. ActiveGenie derives it from the model name or from `config.providers.default`, so setting it has no effect.

### How a model is chosen

ActiveGenie resolves the model and provider in this order, stopping at the first that yields both:

1. Explicit configuration: `config.llm.model` together with `config.providers.default`.
2. Global default: `config.providers.default`, when no model is set.
3. Module recommendation: the module's `recommended_model`, with the provider inferred from the model name.
4. Partial inference: whichever of the two is still missing gets filled in, either the provider from the model name or the provider's `default_model`.
5. Any available provider: the first one holding a valid API key, plus that provider's `default_model`.

If none of these produce a credentialed provider, ActiveGenie raises `WithoutAvailableProviderError`.

```ruby
ActiveGenie.configure do |config|
  config.llm.model = 'deepseek-chat'
  config.llm.temperature = 0.1
  config.llm.max_tokens = 8000
  config.llm.max_retries = 3
  config.llm.retry_delay = 5
end
```

Retries and timeouts are covered in more detail on the [Observability & errors](/reference/observability) page.

## Concurrency

ActiveGenie issues LLM requests concurrently with fibers, using the `async` gem. It batches work in groups of `config.llm.max_fibers` (default `10`), and each batch finishes before the next one starts.

This applies wherever a module has independent work to parallelize. `Ranker` uses it for its scoring pass, its ELO rounds, and its free-for-all matches. Single-request modules like `Extractor` are unaffected.

```ruby
ActiveGenie.configure do |config|
  config.llm.max_fibers = 4 # lower this if you are hitting provider rate limits
end
```

Fibers are cooperative and run on one thread, so this is safe inside a background job or a request cycle. If you run several jobs in parallel, each one opens up to `max_fibers` connections of its own, so the number the provider sees is the product rather than `max_fibers` alone.

## Extractor (`config.extractor`)

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `min_accuracy` | Integer | `70` | Intended confidence floor for an extracted field, on a scale of 0 to 100. |

```ruby
ActiveGenie.configure do |config|
  config.extractor.min_accuracy = 85
end
```

> [!WARNING]
> `min_accuracy` is not currently enforced. `Extractor.with_explanation` asks the model for a per-field `*_accuracy` score and returns those values in `metadata`, but nothing filters them against this threshold. Read the accuracy values yourself if you need to act on them:
>
> ```ruby
> result = ActiveGenie::Extractor.with_explanation(text, schema)
> result.metadata['price_accuracy'] # => 95
> ```

## Lister (`config.lister`)

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `number_of_items` | Integer | `5` | How many items to generate. |

```ruby
ActiveGenie::Lister.call(theme, config: { lister: { number_of_items: 10 } })
```

## Ranker (`config.ranker`)

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `score_variation_threshold` | Integer | `30` | Coefficient of variation, as a percentage, that the field of players must fall below. After the scoring pass, ActiveGenie repeatedly eliminates the lowest-scoring player until the spread drops under this value. Lower it to eliminate more aggressively and run fewer head-to-head matches. |

```ruby
ActiveGenie.configure do |config|
  config.ranker.score_variation_threshold = 25
end
```

## Log (`config.log`)

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `file_path` | String | `'log/active_genie.log'` | Main log file. |
| `fine_tune_file_path` | String | `'log/active_genie_fine_tune.log'` | Log file for fine-tuning data. |
| `output` | Proc | `->(log) { $stdout.puts log }` | Handler for each log entry. It must respond to `call`, otherwise ActiveGenie raises `InvalidLogOutputError`. |
| `additional_context` | Hash | `{}` | Extra key-value pairs merged into every log entry. |

Methods: `add_observer(observers: [], scope: {}, &block)`, `remove_observer(observers)`, `clear_observers`.

```ruby
ActiveGenie.configure do |config|
  config.log.file_path = 'log/genie.log'
  config.log.output = ->(log) { MyLogger.info(log) }
end
```

Observers and the events they receive are documented on the [Observability & errors](/reference/observability) page.

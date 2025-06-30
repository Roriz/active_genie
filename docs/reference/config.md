# ActiveGenie Configuration

ActiveGenie provides a flexible configuration system that can be customized to suit your needs. This document details all available configuration options.

## Basic Configuration

To configure ActiveGenie, use the `ActiveGenie.configure` block in your application's initialization:

```ruby
ActiveGenie.configure do |config|
  # Provider configurations
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']

  # Log configurations
  config.log.file_path = 'log/custom_genie.log'
  config.log.fine_tune_file_path = 'log/fine_tune_genie.log'

  # Other configurations can be added here
end
```

## Configuration Sections

### 1. Log Configuration (`config.log`)

The log configuration controls how ActiveGenie handles logging of its operations.

#### Available Settings:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `file_path` | String | `'log/active_genie.log'` | Path to the main log file where all logs will be written. |
| `fine_tune_file_path` | String | `'log/active_genie_fine_tune.log'` | Path to the fine-tuning specific log file. |
| `output` | Proc | `->(log) { $stdout.puts log }` | Custom output handler for logs. Must respond to `call`. |
| `additional_context` | Hash | `{}` | Additional context to be added to each log entry. |

#### Methods:

- `add_observer(observers: [], scope: {}, &block)`
  - Adds log observers that will be notified of log events.
  - `observers`: An array of callable objects or a single callable object.
  - `scope`: A hash to filter which logs the observer receives.
  - `block`: A block that will be called for matching logs.

- `remove_observer(observers)`
  - Removes the specified observers.

#### Example:

```ruby
ActiveGenie.configure do |config|
  config.log.file_path = 'log/my_app/genie.log'
  config.log.fine_tune_file_path = 'log/my_app/fine_tune.log'

  # Add a custom output handler
  config.log.output = ->(log) { MyLogger.info(log) }

  # Add an observer for specific log events
  config.log.add_observer(scope: { event: :api_call }) do |log|
    StatsD.increment("genie.api_calls")
  end
end
```

### 2. LLM Configuration (`config.llm`)

The LLM configuration is used to define settings for interacting with Large Language Models.

#### Available Settings:

| Setting         | Type                | Default                      | Description                                                                                                |
|-----------------|---------------------|------------------------------|------------------------------------------------------------------------------------------------------------|
| `model`         | String / nil        | `nil`                        | The specific LLM model to use (e.g., 'gpt-4', 'claude-2').                                                 |
| `provider`      | Symbol / nil        | `nil`                        | The LLM provider (e.g., `:openai`, `:anthropic`). Set as a string, stored as a symbol.                       |
| `client`        | Object / nil        | `nil`                        | A pre-configured client instance for the LLM provider. If set, other settings might be ignored.            |
| `temperature`   | Numeric             | `0`                          | Controls randomness. Higher values (e.g., 0.8) = more random, lower (e.g., 0.2) = more deterministic.        |
| `max_tokens`    | Integer             | `4096`                       | Maximum number of tokens to generate in the LLM response.                                                  |
| `max_retries`   | Integer / nil       | `nil`                        | Maximum number of times to retry a failed API call to the LLM.                                             |
| `retry_delay`   | Numeric / nil       | `nil`                        | Delay (in seconds) between retries for failed API calls.                                                   |
| `model_tier`    | Enum [lower_tier, middle_tier, higher_tier]              | `'lower_tier'`               | Specifies the model tier, potentially affecting cost/performance. Will be used if `model` is not set.       |
| `read_timeout`  | Numeric / nil       | `nil`                        | Timeout (in seconds) for reading data from the LLM API.                                                    |
| `open_timeout`  | Numeric / nil       | `nil`                        | Timeout (in seconds) for establishing a connection to the LLM API.                                         |

#### Example:

```ruby
ActiveGenie.configure do |config|
  config.llm.provider = :openai
  config.llm.model = 'gpt-999'
  config.llm.temperature = 0.1
  config.llm.max_tokens = 8000
  config.llm.max_retries = 1
  config.llm.retry_delay = 5 # seconds
  config.llm.model_tier = 'higher_tier' # If model is not set, will use the model tier to select a model
end
```

### 4. Providers Configuration (`config.providers`)

The Providers configuration (`config.providers`) manages settings for various Large Language Model (LLM) providers. It allows you to configure multiple providers, set a default, and access individual provider settings. Active Genie automatically loads configurations for supported providers (OpenAI, Anthropic, DeepSeek, Google).

#### Main Provider Settings:

| Setting   | Type                | Default                        | Description                                                                 |
|-----------|---------------------|--------------------------------|-----------------------------------------------------------------------------|
| `default` | String / Symbol     | First validly configured provider (often `:openai` if its API key is set) | The name of the default LLM provider to use (e.g., `:openai`, `:anthropic`). You can set this to your preferred provider. |

#### Methods for `config.providers`:

-   `add(provider_classes)`
    -   Adds one or more custom provider configuration classes. `provider_classes` can be a single class or an array of classes. (Typically not needed for built-in providers).
-   `remove(provider_classes)`
    -   Removes one or more provider configurations based on their classes.

#### Example for Main Provider Settings:

```ruby
ActiveGenie.configure do |config|
  # Set the default provider to use if not specifying one explicitly in operations
  config.providers.default = :anthropic

  # Configure individual providers (API keys are often set via ENV variables)
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.providers.anthropic.api_key = ENV['ANTHROPIC_API_KEY']
  # config.providers.deepseek.api_key = ENV['DEEPSEEK_API_KEY']
  # config.providers.google.api_key = ENV['GEMINI_API_KEY']
end
```

#### Individual Provider Configurations:

The following subsections detail the configurations for each supported LLM provider. Each provider configuration (e.g., `config.providers.openai`) allows setting an `api_key`, `api_url`, and specific model names for `lower_tier_model`, `middle_tier_model`, and `higher_tier_model`.

##### a. OpenAI (`config.providers.openai`)

Internal Name: `:openai`

| Setting             | Type   | Default                               | Description                                                                 |
|---------------------|--------|---------------------------------------|-----------------------------------------------------------------------------|
| `api_key`           | String | `ENV['OPENAI_API_KEY']`               | Your OpenAI API key.                                                        |
| `api_url`           | String | `'https://api.openai.com/v1'`         | Base URL for the OpenAI API.                                                |
| `lower_tier_model`  | String | `'gpt-4.1-mini'`                      | Model for lower-tier usage (cost-effective, faster).                        |
| `middle_tier_model` | String | `'gpt-4.1'`                           | Model for middle-tier usage (balanced performance).                         |
| `higher_tier_model` | String | `'o3-mini'`                           | Model for higher-tier usage (most capable).                                 |

##### b. Anthropic (`config.providers.anthropic`)

Internal Name: `:anthropic`

| Setting             | Type   | Default                                  | Description                                                                 |
|---------------------|--------|------------------------------------------|-----------------------------------------------------------------------------|
| `api_key`           | String | `ENV['ANTHROPIC_API_KEY']`               | Your Anthropic API key.                                                     |
| `api_url`           | String | `'https://api.anthropic.com'`            | Base URL for the Anthropic API.                                             |
| `anthropic_version` | String | `'2023-06-01'`                           | The API version for Anthropic.                                              |
| `lower_tier_model`  | String | `'claude-3-5-haiku-20241022'`            | Model for lower-tier usage.                                                 |
| `middle_tier_model` | String | `'claude-3-7-sonnet-20250219'`           | Model for middle-tier usage.                                                |
| `higher_tier_model` | String | `'claude-3-opus-20240229'`               | Model for higher-tier usage.                                                |

##### c. DeepSeek (`config.providers.deepseek`)

Internal Name: `:deepseek`

| Setting             | Type   | Default                               | Description                                                                 |
|---------------------|--------|---------------------------------------|-----------------------------------------------------------------------------|
| `api_key`           | String | `ENV['DEEPSEEK_API_KEY']`             | Your DeepSeek API key.                                                      |
| `api_url`           | String | `'https://api.deepseek.com/v1'`       | Base URL for the DeepSeek API.                                              |
| `lower_tier_model`  | String | `'deepseek-chat'`                     | Model for lower-tier usage.                                                 |
| `middle_tier_model` | String | `'deepseek-chat'`                     | Model for middle-tier usage.                                                |
| `higher_tier_model` | String | `'deepseek-reasoner'`                 | Model for higher-tier usage.                                                |

##### d. Google (`config.providers.google`)

Internal Name: `:google`

| Setting             | Type   | Default                                                       | Description                                                                 |
|---------------------|--------|---------------------------------------------------------------|-----------------------------------------------------------------------------|
| `api_key`           | String | `ENV['GENERATIVE_LANGUAGE_GOOGLE_API_KEY']` or `ENV['GEMINI_API_KEY']` | Your Google API key for Gemini.                                           |
| `api_url`           | String | `'https://generativelanguage.googleapis.com'`                 | Base URL for the Google Generative Language API.                            |
| `lower_tier_model`  | String | `'gemini-2.0-flash-lite'`                                     | Model for lower-tier usage.                                                 |
| `middle_tier_model` | String | `'gemini-2.0-flash'`                                          | Model for middle-tier usage.                                                |
| `higher_tier_model` | String | `'gemini-2.5-pro-experimental'`                               | Model for higher-tier usage.                                                |

#### Example for Overriding Individual Provider Settings:

```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = 'sk-yourOpenAiKey...'
  config.providers.openai.middle_tier_model = 'gpt-4o' # Override default middle tier for OpenAI

  config.providers.anthropic.api_key = 'sk-ant-yourAnthropicKey...'
  config.providers.anthropic.anthropic_version = '2024-02-15' # Override Anthropic API version

  config.providers.google.higher_tier_model = 'gemini-1.5-pro-latest' # Use a specific Google model
end
```

### 5. Ranking Configuration (`config.ranking`)

The Ranking configuration (`config.ranking`) deals with settings related to how results or items are ranked.

#### Available Settings:

| Setting                     | Type    | Default | Description                                                                                                |
|-----------------------------|---------|---------|------------------------------------------------------------------------------------------------------------|
| `score_variation_threshold` | Integer | `30`    | A threshold (percentage) used to determine significant variations in scores when ranking or comparing items. |

#### Example:

```ruby
ActiveGenie.configure do |config|
  config.ranking.score_variation_threshold = 25 # Set to 25%
end
```

### 6. Data Extractor Configuration (`config.data_extractor`)

The Data Extractor configuration (`config.data_extractor`) provides settings for how data is extracted and processed, likely from text or other sources using LLMs.

#### Available Settings:

| Setting            | Type    | Default | Description                                                                                             |
|--------------------|---------|---------|---------------------------------------------------------------------------------------------------------|
| `with_explanation` | Boolean | `true`  | Whether the data extraction process should also attempt to provide an explanation for the extracted data. |
| `min_accuracy`     | Integer | `70`    | The minimum accuracy (percentage) required for extracted data to be considered valid or useful.         |
| `verbose`          | Boolean | `false` | If true, enables more detailed logging or output from the data extraction process.                      |

#### Example:

```ruby
ActiveGenie.configure do |config|
  config.data_extractor.with_explanation = false
  config.data_extractor.min_accuracy = 85
  config.data_extractor.verbose = true
end
```

# Installation

## Requirements

- Ruby 3.4.0 or newer
- An API key for at least one supported provider: OpenAI, Anthropic, DeepSeek, or Google

ActiveGenie has one runtime dependency, `async`, which it uses to issue provider requests concurrently.

## Install

Add it to your Gemfile:

```ruby
gem 'active_genie'
```

Then:

```shell
bundle install
```

Or install it directly:

```shell
gem install active_genie
```

## Configure

ActiveGenie reads API keys from the environment, so the minimum setup is to export one:

```shell
export OPENAI_API_KEY="sk-..."
```

That's enough to start:

```ruby
require 'active_genie'

ActiveGenie::Extractor.call("Nike Air Max 90 - $199.99", { brand: { type: 'string' } }).data
# => { brand: "Nike" }
```

Each provider has its own environment variable:

| Provider | Environment variable |
| :--- | :--- |
| OpenAI | `OPENAI_API_KEY` |
| Anthropic | `ANTHROPIC_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| Google | `GENERATIVE_LANGUAGE_GOOGLE_API_KEY`, falling back to `GEMINI_API_KEY` |

To set keys explicitly, or to change any other default, use a configuration block somewhere in your boot sequence:

```ruby
require 'active_genie'

ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.providers.default = :openai
end
```

See [Configuration](/reference/config) for the full set of options.

## Rails

The steps above work unchanged in Rails. If you'd like a commented initializer to start from, ActiveGenie ships a Rake task that writes one.

Load the tasks in your `Rakefile`:

```ruby
ActiveGenie.load_tasks
```

Then generate the initializer:

```shell
bundle exec rake active_genie:install
```

This writes `config/initializers/active_genie.rb`. Because the task assumes that directory already exists, it only works in a Rails application. Everywhere else, put your configuration block wherever you boot the application.

> [!NOTE]
> The generated file is a commented template. A few of the examples in it refer to settings that no longer exist, so check [Configuration](/reference/config) for what the current version actually supports.

## Verify

```ruby
require 'active_genie'

ActiveGenie::Comparator.call("a fresh apple", "a rotten apple", "which is better to eat?").data
# => "a fresh apple"
```

If you have not set a key for any provider, the call raises `ActiveGenie::WithoutAvailableProviderError`. See [Observability & errors](/reference/observability) for the full list of failures and how to handle them.

## Next steps

- [Quickstart](/introduction/quickstart) walks through the five modules with working examples.
- [What is ActiveGenie?](/introduction/what-is-active-genie) explains the design and the guarantees behind it.
- [Configuration](/reference/config) documents providers, models, retries, and concurrency.

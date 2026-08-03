# ActiveGenie 🧞‍♂️
> The Lodash for GenAI: Consistent + Model-Agnostic

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml)

**ActiveGenie** is a toolkit for building GenAI features in Ruby. Its modules are model-agnostic and work across providers. `ActiveGenie::Comparator` settles subjective comparisons by staging a structured debate between the two inputs. `ActiveGenie::Scorer` grades content with a jury of domain experts. `ActiveGenie::Ranker` orders large datasets with a tournament system.

Results stay consistent for three reasons:

* Custom benchmarking: every version and model update is tested for consistency.
* Reasoning prompting: prompts borrow human reasoning techniques, like debate and jury review, to shape how the model thinks.
* Overfitted prompts: each module uses a specialized prompt built for one purpose.

## Requirements

- Ruby >= 3.4.0
- An API key for OpenAI, Anthropic, DeepSeek, or Google

## Installation

```ruby
gem 'active_genie'
```

```shell
bundle install
```

Export a key for any supported provider:

```shell
export OPENAI_API_KEY="sk-..."
```

See the [installation guide](https://activegenie.ai/introduction/installation) for Rails setup and explicit configuration.

## Quick start

```ruby
require 'active_genie'

text = "Nike Air Max 90 - Size 42 - $199.99"
schema = {
  brand: { type: 'string', enum: %w[Nike Adidas Puma] },
  price: { type: 'number', minimum: 0 },
  size:  { type: 'number', minimum: 35, maximum: 46 }
}

result = ActiveGenie::Extractor.call(text, schema)

result.data
# => { brand: "Nike", price: 199.99, size: 42 }

result.reasoning
# => "Brand name appears at the start of the listing, price in USD at the end."
```

Every module returns an `ActiveGenie::Result` with `data`, `reasoning`, and `metadata`.

```ruby
ActiveGenie::Scorer.call(text, criteria).data       # => 91
ActiveGenie::Comparator.call(a, b, criteria).data   # => the winning input
ActiveGenie::Lister.call(theme).data                # => ["Price", "Battery life", ...]
ActiveGenie::Ranker.call(items, criteria).data      # => items, best first
```

## Documentation

Full documentation is at [activegenie.ai](https://activegenie.ai):

- [Quickstart](https://activegenie.ai/introduction/quickstart)
- [Configuration](https://activegenie.ai/reference/config)
- [Benchmark results](https://activegenie.ai/benchmark/latest)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

# ActiveGenie 🧞‍♂️
> The Lodash for GenAI: Real Value + Consistent + Model-Agnostic

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml)

ActiveGenie is a developer-first library for GenAI workflows, designed to help you extract, compare, score, and rank with consistency and model-agnostic. Think of it as the Lodash for GenAI: built for real value, consistent results, and freedom from vendor lock-in. It solves the biggest pain in GenAI today: getting predictable, trustworthy answers across use cases, models, and providers.

Behind the scenes, a custom benchmarking system keeps everything consistent across LLM vendors and versions, release after release.

For full documentation, visit [activegenie.ai](https://activegenie.ai).

# Installation

1. Add to your Gemfile:
```ruby
gem 'active_genie'
```

2. Install the gem:
```shell
bundle install
```

3. Generate the configuration:
```shell
echo "ActiveGenie.load_tasks" >> Rakefile
rails active_genie:install
```

4. Configure your credentials in `config/initializers/active_genie.rb`:
```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
end
```

## Quick start example

Extract structured data from text using AI-powered analysis, handling informal language and complex expressions.

```ruby
text = "Nike Air Max 90 - Size 42 - $199.99"
schema = {
  brand: {
    type: 'string',
    enum: ["Nike", "Adidas", "Puma"]
  },
  price: {
    type: 'number',
    minimum: 0
  },
  size: {
    type: 'number',
    minimum: 35,
    maximum: 46
  }
}

result = ActiveGenie::DataExtractor.call(
  text,
  schema,
  config: { provider: :openai, model: 'gpt-4.1-mini' } # optional
)
# => {
#      brand: "Nike",
#      brand_explanation: "Brand name found at start of text",
#      price: 199.99,
#      price_explanation: "Price found in USD format at end",
#      size: 42,
#      size_explanation: "Size explicitly stated in the middle"
#    }
```

## Documentation

For full documentation, visit [activegenie.ai](https://activegenie.ai).

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 License - see the [LICENSE](LICENSE) file for details.

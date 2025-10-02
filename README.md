# ActiveGenie 🧞‍♂️
> The Lodash for GenAI: Consistent + Model-Agnostic

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml)

**ActiveGenie** is an **enabler for creating reliable GenAI features**, offering powerful, **model-agnostic tools** across any provider. It allows you to settle subjective comparisons with a `ActibeGenie::Comparator` module that stages a political debate, get accurate scores from an **AI jury** using `ActiveGenie::Scorer`, and **rank large datasets** using `ActiveGenie::Ranker`'s tournament-style system.
This reliability is built on three core pillars:
* **Custom Benchmarking:** Testing for consistency with every new version and model update.
* **Reasoning Prompting:** Utilizing human reasoning techniques (like debate and jury review) to control a model's reasoning.
* **Overfitting Prompts:** Highly specialized, and potentially model-specific, prompt for each module's purpose.

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

result = ActiveGenie::Extractor.call(
  text,
  schema,
  config: { provider_name: :openai, model: 'gpt-4.1-mini' } # optional
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

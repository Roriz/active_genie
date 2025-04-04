# ActiveGenie 🧞‍♂️
> The lodash for GenAI, stop reinventing the wheel

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml)

ActiveGenie is a Ruby gem that provides valuable solutions powered by Generative AI (GenAI) models. Just like Lodash or ActiveStorage, ActiveGenie brings a set of Modules reach real value fast and reliable.
ActiveGenie is backed by a custom benchmarking system that ensures consistent quality and performance across different models and providers in every release.

## Installation

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
rails g active_genie:install
```

4. Configure your credentials in `config/initializers/active_genie.rb`:
```ruby
ActiveGenie.configure do |config|
  config.openai.api_key = ENV['OPENAI_API_KEY']
end
```

## Quick Start

### Data Extractor

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
  config: { provider: :openai, model: 'gpt-4o-mini' } # optional
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

*Recommended model*: `gpt-4o-mini`

Features:
- Structured data extraction with type validation
- Schema-based extraction with custom constraints
- Informal text analysis (litotes, hedging)
- Detailed explanations for extracted values

See the [Data Extractor README](lib/active_genie/data_extractor/README.md) for informal text processing, advanced schemas, and detailed interface documentation.

### Scoring
Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers. Get balanced scoring through AI-powered expert reviewers that automatically adapt to your content.

```ruby
text = "The code implements a binary search algorithm with O(log n) complexity"
criteria = "Evaluate technical accuracy and clarity"

result = ActiveGenie::Scoring.basic(
  text,
  criteria,
  config: { provider: :anthropic, model: 'claude-3-5-haiku-20241022' } # optional
)
# => {
#      algorithm_expert_score: 95,
#      algorithm_expert_reasoning: "Accurately describes binary search and its complexity",
#      technical_writer_score: 90,
#      technical_writer_reasoning: "Clear and concise explanation of the algorithm",
#      final_score: 92.5
#    }
```

*Recommended model*: `claude-3-5-haiku-20241022`

Features:
- Multi-reviewer evaluation with automatic expert selection
- Detailed feedback with scoring reasoning
- Customizable reviewer weights
- Flexible evaluation criteria

See the [Scoring README](lib/active_genie/scoring/README.md) for advanced usage, custom reviewers, and detailed interface documentation.

### Battle
AI-powered battle evaluation system that determines winners between two players based on specified criteria.

```ruby
require 'active_genie'

player_1 = "Implementation uses dependency injection for better testability"
player_2 = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Battle.call(
  player_1,
  player_2,
  criteria,
  config: { provider: :google, model: 'gemini-2.0-flash-lite' } # optional
)
# => {
#      winner_player: "Implementation uses dependency injection for better testability",
#      reasoning: "Player 1 implementation demonstrates better maintainability through dependency injection, 
#                 which allows for easier testing and component replacement. While Player 2 has good test coverage, 
#                 the tight coupling makes the code harder to maintain and modify.",
#      what_could_be_changed_to_avoid_draw: "Focus on specific architectural patterns and design principles"
#    }
```

*Recommended model*: `claude-3-5-haiku`

Features:
- Multi-reviewer evaluation with automatic expert selection
- Detailed feedback with scoring reasoning
- Customizable reviewer weights
- Flexible evaluation criteria

See the [Battle README](lib/active_genie/battle/README.md) for advanced usage, custom reviewers, and detailed interface documentation.

### Ranking
The Ranking module provides competitive ranking through multi-stage evaluation:

```ruby
require 'active_genie'

players = ['REST API', 'GraphQL API', 'SOAP API', 'gRPC API', 'Websocket API']
criteria = "Best one to be used into a high changing environment"

result = ActiveGenie::Ranking.call(
  players,
  criteria,
  config: { provider: :google, model: 'gemini-2.0-flash-lite' } # optional
)
# => {
#      winner_player: "gRPC API",
#      reasoning: "gRPC API is the best one to be used into a high changing environment",
#    }
```

*Recommended model*: `gemini-2.0-flash-lite`

- **Multi-phase ranking system** combining expert scoring and ELO algorithms
- **Automatic elimination** of inconsistent performers using statistical analysis
- **Dynamic ranking adjustments** based on simulated pairwise battles, from bottom to top

See the [Ranking README](lib/active_genie/ranking/README.md) for implementation details, configuration, and advanced ranking strategies.

### Text Summarizer (Future)
### Categorizer (Future)
### Language detector (Future)
### Translator (Future)
### Sentiment analyzer (Future)

## Benchmarking 🧪

ActiveGenie includes a comprehensive benchmarking system to ensure consistent, high-quality outputs across different LLM models and providers.

```ruby
# Run all benchmarks
bundle exec rake active_genie:benchmark

# Run benchmarks for a specific module
bundle exec rake active_genie:benchmark[data_extractor]
```

### Latest Results

| Model | Overall Precision |
|-------|-------------------|
| claude-3-5-haiku-20241022 | 92.25% |
| gemini-2.0-flash-lite | 84.25% |
| gpt-4o-mini | 62.75% |
| deepseek-chat | 57.25% |

See the [Benchmark README](benchmark/README.md) for detailed results, methodology, and how to contribute to our test suite.

## Configuration

| Config | Description | Default |
|--------|-------------|---------|
| `provider` | LLM provider (openai, anthropic, etc) | `nil` |
| `model` | Model to use | `nil` |
| `api_key` | Provider API key | `nil` |
| `timeout` | Request timeout in seconds | `5` |
| `max_retries` | Maximum retry attempts | `3` |

> **Note:** Each module can append its own set of configuration, see the individual module documentation for details.

## How to create a new provider

ActiveGenie supports adding custom providers to integrate with different LLM services. To create a new provider:

1. Create a configuration class for your provider in `lib/active_genie/configuration/providers/`:

```ruby
# Example: lib/active_genie/configuration/providers/internal_company_api_config.rb
module ActiveGenie
  module Configuration::Providers
    class InternalCompanyApiConfig < BaseConfig
      NAME = :internal_company_api
      
      # API key accessor with environment variable fallback
      def api_key
        @api_key || ENV['INTERNAL_COMPANY_API_KEY']
      end
      
      # Base API URL
      def api_url
        @api_url || 'https://api.internal-company.com/v1'
      end
      
      # Client instantiation
      def client
        @client ||= ::ActiveGenie::Clients::InternalCompanyApiClient.new(self)
      end
      
      # Model tier definitions
      def lower_tier_model
        @lower_tier_model || 'internal-basic'
      end
      
      def middle_tier_model
        @middle_tier_model || 'internal-standard'
      end
      
      def upper_tier_model
        @upper_tier_model || 'internal-premium'
      end
    end
  end
end
```

2. Register your provider in your configuration:

```ruby
# In config/initializers/active_genie.rb
ActiveGenie.configure do |config|
  # Register your custom provider
  config.providers.register(InternalCompanyApi::Configuration)
  
  # Configure your provider
  config.internal_company_api.api_key = ENV['INTERNAL_COMPANY_API_KEY']
end
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 License - see the [LICENSE](LICENSE) file for details.

# ActiveGenie 🧞‍♂️
> The lodash for GenAI, stop reinventing the wheel

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/ruby.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/ruby.yml)

ActiveGenie is a Ruby gem that provides a polished, production-ready interface for working with Generative AI (GenAI) models. Just like Lodash or ActiveStorage, ActiveGenie simplifies GenAI integration in your Ruby applications.

## Features

- 🎯 **Data Extraction**: Extract structured data from unstructured text with type validation
- 📊 **Data Scoring**: Multi-reviewer evaluation system
- ⚔️ **Data Battle**: Battle between two data like a political debate
- 💭 **Data Ranking**: Consistent rank data using scoring + elo ranking + battles

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
    type: 'integer',
    minimum: 35,
    maximum: 46
  }
}

result = ActiveGenie::DataExtractor.call(text, schema)
# => { 
#      brand: "Nike", 
#      brand_explanation: "Brand name found at start of text",
#      price: 199.99,
#      price_explanation: "Price found in USD format at end",
#      size: 42,
#      size_explanation: "Size explicitly stated in the middle"
#    }
```

Features:
- Structured data extraction with type validation
- Schema-based extraction with custom constraints
- Informal text analysis (litotes, hedging)
- Detailed explanations for extracted values

See the [Data Extractor README](lib/active_genie/data_extractor/README.md) for informal text processing, advanced schemas, and detailed interface documentation.

### Data Scoring
Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers. Get balanced scoring through AI-powered expert reviewers that automatically adapt to your content.

```ruby
text = "The code implements a binary search algorithm with O(log n) complexity"
criteria = "Evaluate technical accuracy and clarity"

result = ActiveGenie::Scoring.basic(text, criteria)
# => {
#      algorithm_expert_score: 95,
#      algorithm_expert_reasoning: "Accurately describes binary search and its complexity",
#      technical_writer_score: 90,
#      technical_writer_reasoning: "Clear and concise explanation of the algorithm",
#      final_score: 92.5
#    }
```

Features:
- Multi-reviewer evaluation with automatic expert selection
- Detailed feedback with scoring reasoning
- Customizable reviewer weights
- Flexible evaluation criteria

See the [Scoring README](lib/active_genie/scoring/README.md) for advanced usage, custom reviewers, and detailed interface documentation.

### Data Battle
AI-powered battle evaluation system that determines winners between two players based on specified criteria.

```ruby
require 'active_genie'

player_1 = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Battle.call(player_1, player_b, criteria)
# => {
#      winner_player: "Implementation uses dependency injection for better testability",
#      reasoning: "Player A's implementation demonstrates better maintainability through dependency injection, 
#                 which allows for easier testing and component replacement. While Player B has good test coverage, 
#                 the tight coupling makes the code harder to maintain and modify.",
#      what_could_be_changed_to_avoid_draw: "Focus on specific architectural patterns and design principles"
#    }
```

Features:
- Multi-reviewer evaluation with automatic expert selection
- Detailed feedback with scoring reasoning
- Customizable reviewer weights
- Flexible evaluation criteria

See the [Battle README](lib/active_genie/battle/README.md) for advanced usage, custom reviewers, and detailed interface documentation.

### Data Ranking
The Ranking module provides competitive ranking through multi-stage evaluation:


```ruby
require 'active_genie'

players = ['REST API', 'GraphQL API', 'SOAP API', 'gRPC API', 'Websocket API']
criteria = "Best one to be used into a high changing environment"

result = ActiveGenie::Ranking.call(players, criteria)
# => {
#      winner_player: "gRPC API",
#      reasoning: "gRPC API is the best one to be used into a high changing environment",
#    }
```

- **Multi-phase ranking system** combining expert scoring and ELO algorithms
- **Automatic elimination** of inconsistent performers using statistical analysis
- **Dynamic ranking adjustments** based on simulated pairwise battles, from bottom to top

See the [Ranking README](lib/active_genie/ranking/README.md) for implementation details, configuration, and advanced ranking strategies.

### Text Summarizer (Future)
### Categorizer (Future)
### Language detector (Future)
### Translator (Future)
### Sentiment analyzer (Future)

## Configuration

| Config | Description | Default |
|--------|-------------|---------|
| `provider` | LLM provider (openai, anthropic, etc) | `nil` |
| `model` | Model to use | `nil` |
| `api_key` | Provider API key | `nil` |
| `timeout` | Request timeout in seconds | `5` |
| `max_retries` | Maximum retry attempts | `3` |

> **Note:** Each module can append its own set of configuration, see the individual module documentation for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 License - see the [LICENSE](LICENSE) file for details.

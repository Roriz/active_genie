# Quick Start

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

*Recommended model*: `gpt-4o-mini`

Features:
- Structured data extraction with type validation
- Schema-based extraction with custom constraints
- Informal text analysis (litotes, hedging)
- Detailed explanations for extracted values

See the [Data Extractor README](/modules/data_extractor) for informal text processing, advanced schemas, and detailed interface documentation.

### Scoring
Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers. Get balanced scoring through AI-powered expert reviewers that automatically adapt to your content.

```ruby
text = "The code implements a binary search algorithm with O(log n) complexity"
criteria = "Evaluate technical accuracy and clarity"

result = ActiveGenie::Scoring.call(
  text,
  criteria,
  config: { provider_name: :anthropic, model: 'claude-3-5-haiku-20241022' } # optional
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

See the [Scoring README](/modules/scoring) for advanced usage, custom reviewers, and detailed interface documentation.

### Battle
AI-powered battle evaluation system that determines winners between two players based on specified criteria.

```ruby
require 'active_genie'

player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Battle.call(
  player_a,
  player_b,
  criteria,
  config: { provider_name: :google, model: 'gemini-2.0-flash-lite' } # optional
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

See the [Battle README](/modules/battle) for advanced usage, custom reviewers, and detailed interface documentation.

### Ranking
The Ranking module provides competitive ranking through multi-stage evaluation:

```ruby
require 'active_genie'

players = ['REST API', 'GraphQL API', 'SOAP API', 'gRPC API', 'Websocket API']
criteria = "Best one to be used into a high changing environment"

result = ActiveGenie::Ranking.call(
  players,
  criteria,
  config: { provider_name: :google, model: 'gemini-2.0-flash-lite' } # optional
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

See the [Ranking README](/modules/ranking) for implementation details, configuration, and advanced ranking strategies.

### OCR to markdown (Future)
### Text Summarizer (Future)
### Categorizer (Future)
### Language detector (Future)
### Translator (Future)
### Sentiment analyzer (Future)

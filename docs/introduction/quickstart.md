# Quick Start

**ActiveGenie** delivers on two core promises: **Consistent** results across providers and models, and **Model-Agnostic** flexibility to use any AI service.

## Extractor
Transform unstructured text into reliable structured data using AI-powered analysis. Extract typed data from messy real-world content while handling informal language, rhetorical devices, and conversational patterns.

```ruby
# Extract from product listing with inconsistent formatting
product_text = "Sony 65\" BRAVIA XR - $1999.99 (Save $500!) Amazing 4K HDR quality"

schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  price: { type: 'number', minimum: 0, description: 'Current price' },
  discount: { type: 'number', minimum: 0, description: 'Discount amount' },
  features: { type: 'array', items: { type: 'string' }, description: 'Key features' }
}

# Works consistently across any AI provider
result = ActiveGenie::Extractor.call(product_text, schema, 
  config: { provider_name: :openai, model: 'gpt-4o-mini' })

# Returns an ActiveGenie::Result instance
result.data
# => {
#      brand: "Sony",
#      display_size: "65\"",
#      price: 1999.99,
#      discount: 500.0,
#      features: ["BRAVIA XR", "4K HDR quality"]
#    }

# Handle informal language and rhetorical devices
review = "The new update isn't terrible, but it's not exactly amazing either"
sentiment_schema = {
  sentiment: { type: 'string', enum: ['positive', 'negative', 'neutral', 'mixed'] },
  satisfaction_level: { type: 'integer', minimum: 1, maximum: 5 }
}

result = ActiveGenie::Extractor.with_litote(review, sentiment_schema)
result.data
# => {
#      sentiment: "mixed",
#      satisfaction_level: 3,
#      message_litote: true,
#      litote_rephrased: "The new update is okay, but it could be better"
#    }
```

## Scorer
Objective evaluation system using AI-powered expert reviewers. Get detailed scoring with transparent reasoning from multiple domain experts that automatically adapt to your content.

```ruby
# Automatic expert selection based on content
code_review = "Added rate limiting with sliding window algorithm, includes comprehensive unit tests and performance benchmarks"
criteria = "Evaluate technical quality, completeness, and engineering best practices"

# Same interface works with any AI provider
result = ActiveGenie::Scorer.call(code_review, criteria,
  config: { provider_name: :anthropic, model: 'claude-3-5-haiku' })

result.data
# => {
#      senior_software_engineer_score: 94,
#      senior_software_engineer_reasoning: "Excellent implementation with proper algorithm choice, comprehensive testing, and performance considerations",
#      technical_architect_score: 89,
#      technical_architect_reasoning: "Strong technical approach, could benefit from documentation of rate limiting strategy",
#      devops_engineer_score: 91,
#      devops_engineer_reasoning: "Good performance benchmarking approach, suggests monitoring and observability awareness",
#      final_score: 91.3
#    }

result.reasoning
# => "Combined evaluation from 3 expert reviewers with weighted scoring methodology"

# Custom expert reviewers for specialized evaluation
medical_text = "Patient shows 17% improvement in cardiac ejection fraction following 6-week therapy protocol"
reviewers = ["Cardiologist", "Clinical Researcher", "Medical Writer"]

result = ActiveGenie::Scorer.call(medical_text, "Evaluate clinical accuracy and reporting quality", reviewers)
```

## Comparator
Structured debate system that determines winners through AI-powered analysis. Conducts verbal debates where players present arguments, counter-arguments, and final statements before an impartial judge decides.

```ruby
# Code quality comparison with detailed reasoning
player_a = "Implementation uses dependency injection with comprehensive interfaces, enabling easy testing and component replacement"
player_b = "Code achieves 95% test coverage using traditional patterns with proven stability and team familiarity"
criteria = "Evaluate long-term maintainability, testability, and team productivity"

# Consistent debate structure across all AI providers
result = ActiveGenie::Comparator.call(player_a, player_b, criteria,
  config: { provider_name: :google, model: 'gemini-2.0-flash' })

result.data
# => {
#      winner: "Implementation uses dependency injection...",
#      loser: "Code achieves 95% test coverage...",
#      reasoning: "Player A's dependency injection approach provides superior long-term maintainability through loose coupling, while Player B's high coverage is valuable but doesn't address the structural concerns for future development"
#    }

result.reasoning
# => "Structured debate with opening arguments, rebuttals, and final statements evaluated by impartial judge"

# Specialized fight mode for character battles
fighter_a = "Master Crane: graceful fighter using Crane Kung Fu with lightness, precision, and momentum redirection"
fighter_b = "Iron Ox: powerful brawler using Ox Bull Charge style with immense strength and overwhelming mass"
fight_criteria = "Determine winner in one-on-one duel based on skill, strategy, and adaptability"

result = ActiveGenie::Comparator.by_fight(fighter_a, fighter_b, fight_criteria)
```

**Consistent**: Same debate process and winner determination logic across all AI providers  
**Model-Agnostic**: Debate structure adapts to different AI reasoning capabilities seamlessly  

*Recommended models*: `claude-3-5-sonnet`, `gpt-4`, `gemini-2.0-flash`

## Ranker
Sophisticated multi-stage ranking system combining ActiveGenie::Scorer + ActiveGenie::Comparator, statistical elimination, ELO algorithms, and head-to-head battles to produce fair and accurate rankings for any number of players.

```ruby
# Rank API approaches for a specific use case
api_options = [
  "REST API with comprehensive OpenAPI documentation and versioning strategy",
  "GraphQL API with efficient query resolution and real-time subscriptions", 
  "gRPC API with Protocol Buffers and bi-directional streaming capabilities",
  "WebSocket API with custom protocol and connection state management"
]

criteria = "Best choice for real-time collaborative application with complex data relationships"

# Automatic methodology selection based on player count
result = ActiveGenie::Ranker.call(api_options, criteria,
  config: { provider_name: :openai, model: 'gpt-4o' })

result.data
# => {
#      players: [
#        { content: "GraphQL API with efficient query...", score: 89, elo: 1245, rank: 1 },
#        { content: "WebSocket API with custom protocol...", score: 85, elo: 1198, rank: 2 },
#        { content: "gRPC API with Protocol Buffers...", score: 78, elo: 1156, rank: 3 },
#        { content: "REST API with comprehensive...", score: 72, elo: 1089, rank: 4 }
#      ],
#      statistics: { total_players: 4, elo_rounds: 2, ffa_matches: 6 }
#    }

result.reasoning
# => "Ranking determined through multi-stage process: initial scoring, statistical elimination, and ELO-based head-to-head battles"

# Tournament mode for comprehensive ranking
result = ActiveGenie::Ranker.by_tournament(api_options, criteria)

# ELO-only ranking for competitive scenarios  
result = ActiveGenie::Ranker.by_elo(api_options, criteria)

# Simple scoring without battles
result = ActiveGenie::Ranker.by_scoring(api_options, criteria)
```

**Consistent**: Same ranking methodology and fairness algorithms across all AI providers  
**Model-Agnostic**: Ranking logic works with any AI model's scoring and comparison capabilities  

*Recommended models*: `gpt-4`, `claude-3-5-sonnet`, `gemini-2.0-flash`

## Lister  
*Consistent + Model-Agnostic*

Generate ordered lists based on themes using "Family Feud" style survey simulation. Produces lists that reflect general public opinion and cultural consensus, perfect for market research and content planning.

```ruby
# Market research for product development
theme = "Features smartphone users care about most when choosing a new device"

# Works identically across all AI providers
result = ActiveGenie::Lister.call(theme,
  config: { provider_name: :anthropic, model: 'claude-3-5-haiku' })

result.data
# => [
#      "Battery life",
#      "Camera quality", 
#      "Price",
#      "Storage capacity",
#      "Brand reputation",
#      "Screen size",
#      "Processing speed"
#    ]

result.reasoning
# => "List generated using Family Feud style survey simulation reflecting general public opinion"

# Generate expert jury recommendations
content = "Technical proposal for implementing microservices architecture with event-driven communication"
evaluation_criteria = "Assess technical feasibility, business impact, and implementation complexity"

result = ActiveGenie::Lister.with_juries(content, evaluation_criteria)
result.data
# => [
#      "Software Architect",
#      "DevOps Engineer", 
#      "Business Analyst",
#      "Technical Product Manager"
#    ]

# Custom list size
result = ActiveGenie::Lister.call("Most popular breakfast foods worldwide", 
  config: { number_of_items: 10 })
```

**Consistent**: Same ordering logic and popularity assessment across all AI providers  
**Model-Agnostic**: List generation adapts to different AI models' cultural knowledge and reasoning  

*Recommended models*: `gpt-4o-mini`, `claude-3-5-haiku`, `gemini-2.0-flash`

---

## Understanding ActiveGenie::Result

All ActiveGenie modules return an `ActiveGenie::Result` instance with three main components:

```ruby
result = ActiveGenie::Extractor.call(text, schema)

# Access the extracted/generated data
result.data
# => { ... } # The main result (hash, array, etc.)

# Access the reasoning/explanation
result.reasoning  # or result.explanation (alias)
# => "Explanation of how the result was generated"

# Convert to different formats
result.to_h    # => { data: {...}, reasoning: "...", metadata: {...} }
```

This consistent return type across all modules provides:
- **Predictable interface**: Same structure regardless of which module you use
- **Full transparency**: Access to reasoning and metadata for debugging and monitoring
- **Easy serialization**: Built-in methods for converting to hash or JSON

---

## Model-Agnostic Configuration

Switch between any AI provider without changing your application logic:

```ruby
# OpenAI
config = { provider_name: :openai, model: 'gpt-4o-mini' }

# Anthropic  
config = { provider_name: :anthropic, model: 'claude-3-5-haiku' }

# Google
config = { provider_name: :google, model: 'gemini-2.0-flash' }

# DeepSeek
config = { provider_name: :deepseek, model: 'deepseek-chat' }

# Use the same interface for any module
ActiveGenie::Extractor.call(text, schema, config: config)
ActiveGenie::Scorer.call(text, criteria, config: config)  
ActiveGenie::Comparator.call(player_a, player_b, criteria, config: config)
ActiveGenie::Ranker.call(players, criteria, config: config)
ActiveGenie::Lister.call(theme, config: config)
```

## Learn More

- [**Extractor Module**](/modules/extractor) - Advanced schemas, informal text processing, and detailed extraction patterns
- [**Scorer Module**](/modules/scorer) - Custom reviewers, scoring methodologies, and evaluation best practices  
- [**Comparator Module**](/modules/comparator) - Debate structures, fight mode, and comparison strategies
- [**Ranker Module**](/modules/ranker) - Tournament systems, ELO algorithms, and ranking configurations
- [**Lister Module**](/modules/lister) - Survey methodologies, expert juries, and list generation techniques

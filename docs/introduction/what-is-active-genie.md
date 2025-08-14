# What is ActiveGenie?

ActiveGenie is a developer-first library for GenAI workflows, designed to help you compare, rank, score, extract, and list LLM outputs with consistency and model-agnostic flexibility. Think of it as the **Lodash for GenAI**: built for real value, consistent results, and freedom from vendor lock-in. It solves the biggest pain in GenAI today: getting predictable, trustworthy answers across use cases, models, and providers.

> [!TIP]
> Want to try it live? Skip to the [Demo](https://app.activegenie.ai).

> [!TIP]
> Ready to get started? Jump to the [Quickstart](/introduction/quickstart).

## Real Value

ActiveGenie delivers immediate, practical value through five powerful modules that handle the most common GenAI challenges. Each module is designed to solve real problems developers face when working with LLM outputs.

### Smart Comparison with Context Understanding
**Comparator Module** - Conduct structured debates between two options to determine the winner based on your criteria.

Given two code implementations:

```ruby
player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Comparator.call(player_a, player_b, criteria)
# => ComparatorResponse(
#      winner: "Implementation uses dependency injection for better testability",
#      reasoning: "Player A's implementation demonstrates better maintainability through dependency injection..."
#    )
```

**Real-world applications:**
- **Product decisions**: Compare features, designs, or approaches
- **Hiring**: Evaluate candidate responses or portfolios
- **A/B testing**: Choose between marketing copy variants
- **Technical decisions**: Select between architectural approaches

### Intelligent Data Extraction from Unstructured Text
**Extractor Module** - Transform messy, unstructured text into clean, structured data with context awareness and informal language processing.

```ruby
product_text = "Sony 65\" Class BRAVIA XR X95K 4K HDR Mini LED TV - $1999.99 (Save $500)"
schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  price: { type: 'number', minimum: 0, description: 'Current price' },
  discount: { type: 'number', minimum: 0, description: 'Discount amount if any' }
}

result = ActiveGenie::Extractor.call(product_text, schema)
# => {
#      brand: "Sony",
#      display_size: "65\"",
#      price: 1999.99,
#      discount: 500
#    }
```

**Real-world applications:**
- **E-commerce**: Parse product listings and reviews
- **Customer support**: Extract insights from support tickets
- **Social media**: Analyze posts and comments with informal language
- **Content management**: Structure documents and articles

### Survey-Style List Generation
**Lister Module** - Generate ordered lists based on popular opinion, simulating "Family Feud" style surveys for market research and content planning.

```ruby
theme = "Factors consumers consider when buying a smartphone"
result = ActiveGenie::Lister.call(theme)
# => [
#      "Price",
#      "Battery life", 
#      "Camera quality",
#      "Storage capacity",
#      "Brand reputation"
#    ]
```

**Real-world applications:**
- **Market research**: Understand consumer priorities and preferences
- **Content strategy**: Generate topic ideas based on popular demand
- **Product planning**: Identify key features customers value most
- **Competitive analysis**: List industry challenges or opportunities

### Multi-Stage Tournament Ranking
**Ranker Module** - Organize and rank multiple options through sophisticated evaluation combining scoring, ELO ratings, and head-to-head comparisons.

```ruby
solutions = [
  "Uses modern design patterns with proper separation of concerns",
  "Implementation uses dependency injection for better testability", 
  "Code has comprehensive documentation and clear naming conventions",
  "Legacy code with tightly coupled components but working functionality"
]

criteria = "Evaluate code quality, maintainability, and software engineering best practices"

result = ActiveGenie::Ranker.call(solutions, criteria)
# => {
#      players: [
#        { content: "Uses modern design patterns...", score: 85, elo: 1245, rank: 1 },
#        { content: "Implementation uses dependency injection...", score: 82, elo: 1198, rank: 2 },
#        # ... more ranked results
#      ]
#    }
```

**Real-world applications:**
- **Candidate evaluation**: Rank job applicants based on qualifications
- **Content curation**: Prioritize articles, posts, or media
- **Product comparison**: Rank features, vendors, or solutions
- **Performance analysis**: Evaluate team members or submissions

### Expert-Powered Quality Scoring
**Scorer Module** - Get objective quality assessments with detailed feedback from AI-powered expert reviewers across any domain.

```ruby
content = "Patient shows significant improvement in cardiac function with ejection fraction increased from 45% to 62%"
criteria = "Evaluate medical accuracy, clarity, and clinical relevance"

result = ActiveGenie::Scorer.call(content, criteria)
# => {
#      "cardiologist_score" => 94,
#      "cardiologist_reasoning" => "Clinically significant improvement in ejection fraction...",
#      "medical_writer_score" => 87,
#      "clinical_researcher_score" => 91,
#      "final_score" => 90.7
#    }
```

**Real-world applications:**
- **Content quality**: Evaluate articles, documentation, or marketing copy
- **Code review**: Assess implementation quality and best practices
- **Compliance**: Score content against regulatory or brand standards
- **Performance evaluation**: Rate proposals, submissions, or responses


## Consistent

ActiveGenie ensures reliable, high-quality outputs through comprehensive benchmarking across different LLM models and providers. Our continuous testing system validates performance with real-world scenarios and provides transparency in model selection.

### Rigorous Benchmarking System

Every release includes automated testing across multiple scenarios:

| Module | Best Precision | Recommended Model | Performance |
|--------|----------------|-------------------|-------------|
| **Extractor** | 93% | `gpt-4o-mini` | Excellent data extraction accuracy |
| **Comparator** | 91% | `gpt-4o-mini` | Consistent decision-making across models |
| **Scorer** | 82% | `deepseek-chat` | Reliable quality assessment |
| **Ranker** | 100% | `gpt-4o-mini` | Perfect ranking precision |
| **Lister** | N/A | Model-agnostic | Stable list generation |

*Based on our latest benchmark results with 400+ test cases*

### Why Benchmarking Matters for LLM Applications

Our comprehensive testing prevents common LLM pitfalls:

- **Quality Assurance**: Maintains consistent output quality across different models and versions
- **Performance Comparison**: Provides objective metrics to compare LLM providers and models  
- **Cost Optimization**: Identifies the most cost-effective models that meet quality requirements
- **Reliability Tracking**: Monitors performance over time to detect regressions or improvements
- **Feature Validation**: Verifies that specialized modules perform as expected in production

### Continuous Quality Monitoring

With every new release, we run our benchmarking system across:
- **400+ test cases** covering real-world scenarios
- **Multiple LLM providers** (OpenAI, Anthropic, Google, DeepSeek)
- **Diverse use cases** from technical to creative content
- **Performance metrics** including accuracy, speed, and cost efficiency

This ensures that ActiveGenie modules continue to function reliably even as LLM models evolve and update.

### Real-World Test Coverage

Our benchmark includes practical scenarios like:
- **Code quality evaluation** - Assessing technical implementations
- **Product comparisons** - Choosing between alternatives based on criteria  
- **Content extraction** - Parsing unstructured data from various sources
- **Expert ranking** - Multi-stage tournament evaluation
- **Market research** - Survey-style opinion generation

See our [detailed benchmark results](/benchmark/latest) for methodology, performance metrics, and how you can contribute to our test suite.

## Model-Agnostic

ActiveGenie works seamlessly across all major LLM providers and models, ensuring your applications remain flexible and future-proof. No vendor lock-in means you can choose the best model for each specific use case while maintaining consistent interfaces.

### Supported Providers & Models

**OpenAI**: GPT-4o, GPT-4o-mini, GPT-4 Turbo, GPT-3.5 Turbo  
**Anthropic**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus  
**Google**: Gemini 2.0 Flash, Gemini 1.5 Pro, Gemini 1.5 Flash  
**DeepSeek**: DeepSeek Chat, DeepSeek Coder

### Easy Provider Switching

Configure any provider with simple setup:

```ruby
# Use OpenAI for high-accuracy tasks
ActiveGenie.configure do |config|
  config.providers.openai.api_key = "your-openai-key"
  config.providers.openai.model = "gpt-4o"
end

# Switch to Anthropic for creative tasks
result = ActiveGenie::Comparator.call(
  player_a, player_b, criteria,
  config: { providers: { anthropic: { model: "claude-3-5-sonnet" } } }
)

# Use DeepSeek for cost-effective scoring
ActiveGenie::Scorer.call(content, criteria, config: {
  providers: { deepseek: { model: "deepseek-chat" } }
})
```

### Provider-Optimized Prompting

Each module automatically optimizes prompts for different providers:

- **Model-specific formatting** - Adapts to each provider's preferred structure
- **Token efficiency** - Optimizes context usage for cost and performance
- **Provider strengths** - Leverages unique capabilities (e.g., Claude's analysis, GPT's creativity)
- **Fallback handling** - Graceful degradation when providers are unavailable

### Freedom from Vendor Lock-in

**No proprietary formats**: All inputs and outputs use standard data types  
**Consistent interfaces**: Same method signatures across all providers  
**Portable configurations**: Easy migration between providers  
**Independent operation**: Each module works with any supported model

### Future-Proof Architecture

As the LLM landscape evolves rapidly, ActiveGenie adapts:

- **New provider integration** - Quick addition of emerging LLM providers
- **Model updates** - Automatic compatibility with model upgrades
- **Performance optimization** - Continuous improvement based on provider strengths
- **Cost efficiency** - Choose optimal model/provider combinations for your budget

### Provider Recommendations by Use Case

Based on our benchmark results:

| Use Case | Recommended Provider | Model | Why |
|----------|---------------------|-------|-----|
| **Data Extraction** | OpenAI | `gpt-4o-mini` | 93% accuracy, cost-effective |
| **Code Comparison** | OpenAI | `gpt-4o-mini` | Consistent technical evaluation |
| **Quality Scoring** | DeepSeek | `deepseek-chat` | 82% precision, budget-friendly |
| **Complex Ranking** | OpenAI | `gpt-4o-mini` | 100% precision for multi-stage evaluation |
| **Creative Content** | Anthropic | `claude-3-5-sonnet` | Superior reasoning and creativity |

![Prompt Engineering Chaos](/assets/chaos-ai.webp)

### No More Prompt Engineering Headaches

ActiveGenie eliminates the complexity of keeping up with:
- **Provider-specific best practices** - We handle optimization internally
- **Model-specific techniques** - Each module adapts automatically
- **Prompt engineering trends** - Our benchmarks guide continuous improvement
- **API changes** - Abstracted interfaces protect your code from provider updates

The number of providers and models grows every day, and we're committed to supporting the most important ones. If you need a specific model or provider, please [open an issue](https://github.com/Roriz/active_genie/issues), and we'll prioritize adding it.

---

## Getting Started

Ready to add reliable GenAI capabilities to your application? 

1. **[Installation](/introduction/installation)** - Get ActiveGenie set up in minutes
2. **[Basic Configuration](/introduction/basic-configuration)** - Configure your preferred providers
3. **[Quickstart Guide](/introduction/quickstart)** - Try all five modules with examples
4. **[Module Documentation](/modules/)** - Deep dive into each module's capabilities

Or explore specific modules based on your needs:
- **[Comparator](/modules/comparator)** - For choosing between alternatives
- **[Extractor](/modules/extractor)** - For structuring unstructured data  
- **[Lister](/modules/lister)** - For market research and content planning
- **[Ranker](/modules/ranker)** - For multi-option evaluation and ranking
- **[Scorer](/modules/scorer)** - For quality assessment and expert evaluation

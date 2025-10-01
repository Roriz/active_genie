# What is ActiveGenie?

Building with Generative AI can be chaotic. You get inconsistent outputs, unpredictable behavior, and a constant, time-consuming need to re-engineer prompts for different models. This makes it incredibly difficult to build features that are reliable enough for production.

**ActiveGenie** is your toolkit for taming that chaos. It's an enabler for creating **reliable, production-ready GenAI features** by offering powerful, **model-agnostic tools** that deliver consistent results from any provider.

Instead of wrestling with the low-level complexities of LLMs, you can solve real-world problems with a simple, consistent API.

> [!TIP]
> Convinced already? Jump straight to the [Quickstart Guide](/introduction/quickstart) to get started in minutes.

-----

## See It In Action: What You Can Build

ActiveGenie delivers immediate value through five powerful modules. Each one is a high-level tool designed to handle a common, frustrating GenAI challenge with just a single method call.

### 1. Settle Debates with `ActiveGenie::Comparator`

*Smart Comparison with Context Understanding*

Stop getting ambiguous answers. `Comparator` conducts a structured "political debate" between two options to determine a clear winner based on your criteria, providing detailed reasoning for its choice.

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

**Perfect for:**

  - **A/B testing**: Choosing between marketing copy variants.
  - **Technical decisions**: Selecting the best architectural approach.
  - **Hiring**: Objectively evaluating candidate responses.

### 2. Get Expert Opinions with `ActiveGenie::Scorer`

*Expert-Powered Quality Scoring*

Need an expert evaluation? `Scorer` assembles an **AI jury** of specialists (e.g., a cardiologist, a senior developer, a marketing expert) to provide an objective quality assessment with detailed feedback from multiple perspectives.

```ruby
content = "Patient shows significant improvement in cardiac function with ejection fraction increased from 45% to 62%"
criteria = "Evaluate medical accuracy, clarity, and clinical relevance"

result = ActiveGenie::Scorer.call(content, criteria)
# => {
#      "cardiologist_score" => 94,
#      "cardiologist_reasoning" => "Clinically significant improvement in ejection fraction...",
#      "medical_writer_score" => 87,
#      "final_score" => 90.7
#    }
```

**Perfect for:**

  - **Content quality**: Evaluating articles, documentation, or marketing copy.
  - **Code review**: Assessing implementation quality against best practices.
  - **Compliance**: Scoring content against regulatory or brand standards.

### 3. Rank a Crowd with `ActiveGenie::Ranker`

*Multi-Stage Tournament Ranking*

How do you find the best option out of many? `Ranker` organizes a multi-stage tournament, combining initial scoring, ELO ratings, and head-to-head `Comparator` debates to produce a reliably sorted list.

```ruby
solutions = [
  "Uses modern design patterns with proper separation of concerns",
  "Implementation uses dependency injection for better testability",
  "Legacy code with tightly coupled components but working functionality"
]
criteria = "Evaluate code quality and software engineering best practices"

result = ActiveGenie::Ranker.call(solutions, criteria)
# => {
#      players: [
#        { content: "Uses modern design patterns...", score: 85, elo: 1245, rank: 1 },
#        { content: "Implementation uses dependency injection...", score: 82, elo: 1198, rank: 2 },
#        # ... more ranked results
#      ]
#    }
```

**Perfect for:**

  - **Candidate evaluation**: Ranking job applicants based on qualifications.
  - **Product comparison**: Ranking features, vendors, or solutions.
  - **Content curation**: Prioritizing articles, posts, or media.

### 4. Structure Any Text with `ActiveGenie::Extractor`

*Intelligent Data Extraction from Unstructured Text*

Turn messy text into clean, structured data. `Extractor` uses your defined schema to parse unstructured text, even handling informal language and complex context with ease.

```ruby
product_text = "Sony 65\" Class BRAVIA XR X95K 4K HDR Mini LED TV - $1999.99 (Save $500)"
schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  price: { type: 'number', minimum: 0, description: 'Current price' }
}

result = ActiveGenie::Extractor.call(product_text, schema)
# => { brand: \"Sony\", display_size: \"65\", price: 1999.99 }
```

**Perfect for:**

  - **E-commerce**: Parsing product listings and reviews.
  - **Customer support**: Extracting structured insights from support tickets.
  - **Content management**: Automatically structuring documents and articles.

### 5. Generate Popular Ideas with `ActiveGenie::Lister`

*Survey-Style List Generation*

Need to know what people think? `Lister` simulates a "Family Feud" style survey to generate ordered lists based on popular opinion, perfect for research and planning.

```ruby
theme = "Factors consumers consider when buying a smartphone"
result = ActiveGenie::Lister.call(theme)
# => [ "Price", "Battery life", "Camera quality", "Storage capacity", "Brand reputation" ]
```

**Perfect for:**

  - **Market research**: Understanding consumer priorities.
  - **Content strategy**: Generating topic ideas based on popular demand.
  - **Product planning**: Identifying key features customers value most.

-----

## The Pillars of ActiveGenie: How We Guarantee Results

Our powerful modules are built on a foundation of principles that ensure reliability, consistency, and flexibility.

### Pillar 1: Unshakeable Consistency

We don't leave quality to chance. ActiveGenie uses a multi-layered approach to force LLMs to produce predictable, high-quality outputs.

  * **Reasoning Prompting**: We use human reasoning techniques to control a model's thought process. Instead of just asking for an answer, we force the model to stage a political debate (`Comparator`) or form a jury of experts (`Scorer`). This structured reasoning provides far more consistent results.
  * **Specialized Prompts**: Each module uses highly specialized prompts that are "overfitted" for a single purpose. This allows for a higher degree of precision and control over the output, making the modules reliable for their specific tasks.
  * **Rigorous Benchmarking**: With every release, we run a suite of **400+ test cases** across multiple providers to validate performance. This prevents regressions, ensures quality, and helps you choose the most cost-effective model for your needs.

| Module | Best Precision | Recommended Model | Performance |
|---|---|---|---|
| **Extractor** | 93% | `gpt-4o-mini` | Excellent data extraction accuracy |
| **Comparator** | 91% | `gpt-4o-mini` | Consistent decision-making across models |
| **Scorer** | 82% | `deepseek-chat` | Reliable quality assessment |
| **Ranker** | 100% | `gpt-4o-mini` | Perfect ranking precision |

*See our [detailed benchmark results](/benchmark/latest) for full methodology and metrics.*

### Pillar 2: True Model Freedom

The LLM landscape changes daily. ActiveGenie is designed to be **model-agnostic**, giving you the freedom to adapt without rewriting your code.

  * **No Vendor Lock-In**: Switch between providers with a single line of configuration. Your application code remains unchanged, protected from breaking API changes and provider-specific quirks.
  * **Use the Best Model for the Job**: Mix and match providers and models to optimize for cost, speed, or accuracy on a per-call basis.

```ruby
# Set OpenAI as the default
ActiveGenie.configure do |config|
  config.providers.openai.api_key = "your-openai-key"
  config.providers.openai.model = "gpt-4o"
end

# Override to use Anthropic for a specific creative task
result = ActiveGenie::Lister.call(
  "Topics for a tech blog",
  config: { providers: { anthropic: { model: "claude-3-5-sonnet" } } }
)
```

  * **No More Prompt Engineering Headaches**: We handle the complexity of provider-specific formatting, token optimization, and best practices internally. You just call the module.

**Supported Providers:** OpenAI, Anthropic, Google, DeepSeek, and more coming soon.

-----

## Your Journey Starts Here

Ready to add reliable GenAI capabilities to your application?

1.  **[Installation](/introduction/installation)** - Get ActiveGenie set up in minutes.
2.  **[Quickstart Guide](/introduction/quickstart)** - Try our modules with hands-on examples.
3.  **[Module Documentation](/modules/comparator)** - Deep dive into each module's advanced capabilities.

Or explore specific modules based on your needs:
- **[Comparator](/modules/comparator)** - For choosing between alternatives
- **[Extractor](/modules/extractor)** - For structuring unstructured data  
- **[Scorer](/modules/scorer)** - For quality assessment and expert evaluation
- **[Lister](/modules/lister)** - For market research and content planning
- **[Ranker](/modules/ranker)** - For multi-option evaluation and ranking

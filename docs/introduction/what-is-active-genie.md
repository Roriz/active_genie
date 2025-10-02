# What is ActiveGenie?

Building with Generative AI can be chaotic. You get inconsistent outputs, unpredictable behavior, and a constant, time-consuming need to re-engineer prompts for different models. This makes it incredibly difficult to build features that are reliable enough for production.

**ActiveGenie** is your toolkit for taming that chaos. It's an enabler for creating **reliable, production-ready GenAI features** by offering powerful, **model-agnostic tools** that deliver consistent results from supported providers.

Instead of wrestling with the low-level complexities of LLMs, you can solve real-world problems with a simple, consistent API.

> [!TIP]
> Convinced already? Jump straight to the [Quickstart Guide](/introduction/quickstart) to get started in minutes.

-----

## See It In Action

### 1. ActiveGenie::Comparator

`Comparator` conducts a structured "political debate" between two players to determine a clear winner based on your criteria, providing detailed reasoning for its choice.

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

  - **Better copy**: Choosing between marketing copy variants.
  - **Best product**: Selecting the best product by abstract criteria.
  - **Balance Gamification**: Compare player strategies to give more points to better ones.

### 2. ActiveGenie::Scorer

`Scorer` assembles an **AI jury** of specialists (e.g., a cardiologist, a senior developer, a marketing expert) to provide an objective quality assessment with detailed feedback from multiple perspectives.

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
  - **Compliance**: Scoring content against regulatory or brand standards.
  - **Assessment**: Evaluating essays, reports, or technical answers.

### 3. ActiveGenie::Ranker

`Ranker` organizes a multi-stage tournament, combining initial scoring + ELO ratings + free for all debates to produce a reliably sorted list.

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

### 4. ActiveGenie::Extractor

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

### 5. ActiveGenie::Lister

`Lister` simulates a "Family Feud" style survey to generate ordered lists based on popular options.

```ruby
theme = "Factors consumers consider when buying a smartphone"
result = ActiveGenie::Lister.call(theme)
# => [ "Price", "Battery life", "Camera quality", "Storage capacity", "Brand reputation" ]
```

**Perfect for:**

  - **Market research**: Understanding consumer priorities.
  - **Content strategy**: Generating topic ideas based on popular demand.
  - **Tags and categories**: Creating relevant tags for articles or products.

-----

## The Pillars of ActiveGenie: How We Guarantee Results

Our modules are built on a foundation of principles that ensure reliability, consistency, and flexibility.

### Pillar 1: Consistency

For consistency we use a multi-layered approach to force LLMs to produce predictable, high-quality outputs.

  * **Reasoning Prompting**: We use human reasoning techniques to control a model's thought process. Instead of just asking for an answer, we force the model to stage a political debate (`Comparator`) or form a jury of experts (`Scorer`). This structured reasoning provides far more consistent results.
  * **Overfitted Prompts**: Each module uses highly specialized prompts that are "overfitted" for a single purpose. This allows for a higher degree of precision and control over the output, making the modules reliable for their specific tasks.

### Pillar 2: Verifiable

With every release, we run a suite of **400+ test cases** across multiple providers to validate performance. This prevents regressions, ensures quality, and helps you choose the most cost-effective model for your needs.

| Module | Best Precision | Recommended Model |
|---|---|---|---|
| **Extractor** | 94% | `deepseek-chat` |
| **Comparator** | 96% | `claude-sonnet-4-20250514` |
| **Scorer** | 83% | `deepseek-chat` |
| **Lister** | 68% | `claude-3-5-haiku-20241022` |
| **Ranker** | 67% | `gemini-2.5-flash` |

*See our [detailed benchmark results](/benchmark/latest) for full methodology and metrics.*

### Pillar 3: Model agnostic

The LLM landscape changes daily. ActiveGenie is designed to be **model-agnostic**, giving you the freedom to adapt without rewriting your code.

  * **No Vendor Lock-In**: Switch between providers with a single line of configuration. Your application code remains unchanged, protected from breaking API changes and provider-specific quirks.
  * **Use the Best Model for the Job**: Mix and match providers and models to optimize for cost, speed, or accuracy on a per-call basis.

```ruby
# Set OpenAI as the default
ActiveGenie.configure do |config|
  config.providers.openai.api_key = "your-openai-key"
  config.providers.anthropic.api_key = "your-anthropic-key"
  config.providers.default = :openai
end

# Override to use Anthropic for a specific creative task
result = ActiveGenie::Lister.call(
  "Topics for a tech blog",
  config: { model: "claude-3-5-haiku-20241022" }
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

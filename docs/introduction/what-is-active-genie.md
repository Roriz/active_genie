# What is ActiveGenie?

LLMs are inconsistent. The same prompt returns different shapes on different days, and output that worked on one model breaks on another. Getting a reliable answer usually means rewriting prompts every time you change providers.

**ActiveGenie** is a Ruby toolkit that puts a stable interface over that. Each module solves one narrowly defined problem, such as extracting fields from text or comparing two options, and returns the same type no matter which provider answered.

> [!TIP]
> Already convinced? Go to the [Quickstart](/introduction/quickstart).

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models. The shape stays stable, but the exact values will differ.

-----

## The five modules

### Extractor

Turns unstructured text into typed data matching a schema you define.

```ruby
product_text = "Sony 65\" Class BRAVIA XR X95K 4K HDR Mini LED TV - $1999.99 (Save $500)"
schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  price: { type: 'number', minimum: 0, description: 'Current price' }
}

ActiveGenie::Extractor.call(product_text, schema).data
# => { brand: "Sony", display_size: "65\"", price: 1999.99 }
```

Useful for parsing product listings, pulling structure out of support tickets, and normalizing documents.

### Scorer

Assembles a jury of domain experts (a cardiologist, a senior developer, a compliance officer) and returns a single score. Each juror's reasoning stays available on the result.

```ruby
content = "Patient shows significant improvement in cardiac function with ejection fraction increased from 45% to 62%"
criteria = "Evaluate medical accuracy, clarity, and clinical relevance"

result = ActiveGenie::Scorer.call(content, criteria)

result.data
# => 91

result.metadata['cardiologist_reasoning']
# => "Clinically significant improvement in ejection fraction, correctly reported."
```

Common uses are content quality, compliance checks, and grading.

### Comparator

Runs a structured debate between two options, then an impartial judge picks one.

```ruby
player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"

ActiveGenie::Comparator.call(player_a, player_b, "Evaluate code quality and maintainability").data
# => "Implementation uses dependency injection for better testability"
```

The winner comes back exactly as you passed it in, so you can compare it against your original input directly. Useful for choosing between copy variants, products, or strategies.

### Lister

Simulates a public survey and returns answers ordered by how commonly people would name them.

```ruby
ActiveGenie::Lister.call("Factors consumers consider when buying a smartphone").data
# => ["Price", "Battery life", "Camera quality", "Storage capacity", "Brand reputation"]
```

Useful for market research, content planning, and generating tags. The ordering reflects popular opinion rather than factual ranking.

### Ranker

Orders a list by running a tournament: scoring, elimination, ELO rounds, then head-to-head debates.

```ruby
solutions = [
  "Uses modern design patterns with proper separation of concerns",
  "Implementation uses dependency injection for better testability",
  "Legacy code with tightly coupled components but working functionality"
]

ActiveGenie::Ranker.call(solutions, "Evaluate software engineering best practices").data
# => ["Uses modern design patterns...", "Implementation uses dependency injection...", "Legacy code..."]
```

Useful for candidate evaluation, vendor comparison, and content curation. It is also the most expensive module. See [Cost](/modules/ranker#cost).

-----

## How consistency is achieved

### One return type

Every module returns an `ActiveGenie::Result` with `data`, `reasoning`, and `metadata`. `data` is narrow (the score, the winner, the list), so your code never has to parse prose. `metadata` carries the full underlying response for debugging.

### Reasoning prompting

Rather than asking a model for an answer, ActiveGenie makes it work through a structure: a debate with counter-arguments (`Comparator`), a panel of experts scoring independently (`Scorer`), a survey simulation (`Lister`). Forcing the reasoning path produces far more stable results than asking directly.

### Overfitted prompts

Each module uses a prompt built for exactly one job. That trades generality for precision: the prompts do not generalize to other tasks, but they handle their own reliably.

-----

## Verified against real providers

ActiveGenie ships a 100-test end-to-end suite that runs against live provider APIs without mocks or recorded fixtures. Assertions check decision quality rather than only whether a response parsed.

Best mean pass rate per module, across three runs in August 2026:

| Module | Best pass rate | Model |
| :--- | :---: | :--- |
| `Comparator` | 100% | `gpt-5.6-luna`, `gemini-3.5-flash-lite`, `deepseek-v4-flash` |
| `Extractor` | 100% | `gpt-5.6-luna`, `claude-haiku-4-5` |
| `Lister` | 100% | `gpt-5.6-luna`, `claude-haiku-4-5`, `deepseek-v4-flash` |
| `Scorer` | 100% | `gemini-3.5-flash-lite` |
| `Ranker` | 75% | `gpt-5.6-luna`, `deepseek-v4-flash` |

Across three full runs per provider, `gpt-5.6-luna` averaged 93.7%, `claude-haiku-4-5` 92.7%, `gemini-3.5-flash-lite` 91.3%, and `deepseek-v4-flash` 87.3%. The first three overlap within run-to-run noise, so treat them as a tie and choose on cost or latency. `Ranker` trails the other modules because of a known bug in `Ranker.by_scoring` rather than model quality.

See the [benchmark](/benchmark/latest) for the full methodology, per-module breakdowns, and notable failures.

-----

## Model agnostic

You select providers in configuration, and you can override the model for a single call.

```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.providers.anthropic.api_key = ENV['ANTHROPIC_API_KEY']
  config.providers.default = :openai
end

# Override for one call. The provider is inferred from the model name.
ActiveGenie::Lister.call("Topics for a tech blog",
  config: { llm: { model: 'claude-haiku-4-5' } })
```

ActiveGenie handles provider-specific request formats, schema quirks, and response shapes internally, so your call site stays the same when you switch.

Supported providers are OpenAI, Anthropic, Google, and DeepSeek.

-----

## Where to go next

1. [Installation](/introduction/installation) covers requirements and setup.
2. [Quickstart](/introduction/quickstart) walks through all five modules with working examples.
3. [Configuration](/reference/config) documents providers, models, retries, and concurrency.

Or jump to a module: [Extractor](/modules/extractor) · [Scorer](/modules/scorer) · [Comparator](/modules/comparator) · [Lister](/modules/lister) · [Ranker](/modules/ranker)

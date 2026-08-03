# Lister

Generates an ordered list of items for a theme, ranked by how commonly people would name them.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models, so expect the same shape of result with different values in it.

## How it works

`Lister` has two strategies.

Feud, the default, simulates a Family Feud survey. The model works out what a group of ordinary people would say if you asked them the question, then returns the answers in the order they would come up. What you get back is popular consensus, closer to cultural familiarity than to expert opinion or a factual ranking.

Juries takes a piece of content and a criteria, then returns the expert roles best suited to evaluating it. [`Scorer`](/modules/scorer) uses this internally to assemble its jury.

## Basic usage

```ruby
theme = "Industries most likely to be affected by climate change"

result = ActiveGenie::Lister.call(theme)

result.data
# => ["Agriculture", "Insurance", "Tourism", "Fishing", "Real Estate"]

result.reasoning
# => "Agriculture and insurance are the two most frequently cited because their
#     exposure is direct and widely reported."
```

Control the length with `config.lister.number_of_items`:

```ruby
ActiveGenie::Lister.call("Most popular breakfast foods",
  config: { lister: { number_of_items: 8 } })
```

## Interface

### `.call(theme, config: {})`

Generates a survey-style list. This is an alias for `.with_feud`.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `theme` | String | The question or topic to survey. |
| `config` | Hash | Per-call configuration overrides. See [Configuration](/reference/config). |

### `.with_feud(theme, config: {})`

Identical to `.call`. Use it when you want the strategy named explicitly at the call site.

### `.with_juries(text, criteria, config: {})`

Returns the expert roles suited to evaluating the given content against the given criteria.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `text` | String | The content that needs evaluating. |
| `criteria` | String | What the evaluation should assess. |
| `config` | Hash | Per-call configuration overrides. |

```ruby
result = ActiveGenie::Lister.with_juries(
  "A technical proposal for implementing microservices architecture",
  "Evaluate technical feasibility and business impact"
)

result.data
# => ["Software Architect", "DevOps Engineer", "Business Analyst"]
```

`number_of_items` does not apply here. The model picks however many juries the content calls for.

## Return value

Returns an [`ActiveGenie::Result`](/introduction/quickstart#understanding-activegenie-result).

| Accessor | Type | Contents |
| :--- | :--- | :--- |
| `data` | Array&lt;String&gt; | The list, ordered most to least common. Empty array if the model returns nothing usable. |
| `reasoning` | String | Why these items, in this order. |
| `metadata` | Hash | The raw provider response, keyed by strings. |

## Configuration

| Setting | Default | Applies to | Description |
| :--- | :--- | :--- | :--- |
| `config.lister.number_of_items` | `5` | `.call`, `.with_feud` | How many items to generate. |

```ruby
ActiveGenie::Lister.call(theme, config: { lister: { number_of_items: 10 } })
```

> [!WARNING]
> `number_of_items` goes to the model as an instruction. ActiveGenie does not enforce the count afterwards. You will get the requested number in almost all cases, but check `data.size` before you index into fixed positions.

ActiveGenie tunes `.with_feud` against `claude-haiku-4-5-20251001` and `.with_juries` against `deepseek-chat`. See [Configuration](/reference/config) for the full set of options and [Observability & errors](/reference/observability) for failure handling.

## Cost

Both strategies make one LLM call per invocation, whatever you set `number_of_items` to.

## Tips

- Write the theme as a survey question. "Comfort foods people crave in winter" works, where a bare "food" gives the model nothing to survey.
- The order means something. Items come back sorted by popular consensus, so the first few are what most people would name straight away.
- Feud gives you opinion rather than fact. That suits market research, where what people believe matters. For items ordered by merit, use [`Ranker`](/modules/ranker) instead.
- Keep technical themes away from Feud. The method assumes ordinary people have opinions on the subject. Ask for "Best Rust async runtimes" and you get a list that looks plausible while resting on no survey at all.
- Answers carry cultural bias. They follow the model's training distribution, which skews toward English-language, Western consensus. Name the market in the theme if you need a specific one.
- Check the size before you index. Prefer `data.first(3)` over `data[2]`.

## Examples

### Market research

```ruby
ActiveGenie::Lister.call("Factors consumers consider when buying a smartphone")
# => ["Price", "Battery life", "Camera quality", "Storage capacity", "Brand reputation"]
```

### Content planning

```ruby
ActiveGenie::Lister.call("Topics people want to learn about in online courses",
  config: { lister: { number_of_items: 10 } })
```

### Reusing a jury across a batch

```ruby
criteria = "Evaluate technical feasibility and business impact"
juries = ActiveGenie::Lister.with_juries(sample_proposal, criteria).data

proposals.map { |p| ActiveGenie::Scorer.call(p, criteria, juries) }
```

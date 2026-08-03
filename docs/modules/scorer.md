# Scorer

Scores text from 0 to 100 against a criteria, with a panel of domain experts.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models. The shape of the result stays the same, but the exact numbers will differ from what you see here.

## How it works

`Scorer` assembles a jury and averages its verdicts:

1. If you don't supply juries, `Scorer` asks [`Lister.with_juries`](/modules/lister#with-juries-text-criteria-config) which expert roles suit the text and criteria.
2. Each jury scores the text independently, 0-100, with its own reasoning.
3. `Scorer` combines those scores into a `final_score` with summary reasoning.

Picking the juries from the content is what makes the score meaningful. Medical text gets scored by a cardiologist and a medical writer instead of by a generic reviewer.

## Basic usage

```ruby
content = "Added rate limiting with a sliding window algorithm, including unit tests and performance benchmarks"
criteria = "Evaluate technical quality, completeness, and engineering best practices"

result = ActiveGenie::Scorer.call(content, criteria)

result.data
# => 91

result.reasoning
# => "All three reviewers rate the implementation highly, citing the appropriate
#     algorithm choice and the presence of both tests and benchmarks."
```

Supply your own juries when you know which perspectives matter:

```ruby
juries = ["Cardiologist", "Clinical Researcher", "Medical Writer"]

result = ActiveGenie::Scorer.call(
  "Patient shows 17% improvement in cardiac ejection fraction following a 6-week therapy protocol",
  "Evaluate clinical accuracy and reporting quality",
  juries
)
```

## Interface

### `.call(text, criteria, juries = [], config: {})`

Scores the text. Alias for `.by_jury_bench`.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `text` | String | The content to score. |
| `criteria` | String | What the juries should evaluate against. |
| `juries` | Array&lt;String&gt; | Optional. Expert roles to use. When empty, Scorer picks them from the content. |
| `config` | Hash | Per-call configuration overrides. See [Configuration](/reference/config). |

`juries` is a **positional** parameter, not a keyword. (`Ranker` takes the same concept as a keyword. See its page.)

### `.by_jury_bench(text, criteria, juries = [], config: {})`

Identical to `.call`. Use it when you want the strategy named explicitly at the call site.

## Return value

Returns an [`ActiveGenie::Result`](/introduction/quickstart#understanding-activegenie-result).

| Accessor | Type | Contents |
| :--- | :--- | :--- |
| `data` | Numeric | **The final score, 0-100.** A single number, not a hash. |
| `reasoning` | String | Summary reasoning behind the final score. |
| `metadata` | Hash | Per-jury scores and reasoning, keyed by strings. |

> [!IMPORTANT]
> `result.data` is the score itself. The per-jury breakdown lives in `metadata`, with **string** keys derived from each jury's role.

```ruby
result = ActiveGenie::Scorer.call("The sky is blue.", "Factual accuracy")

result.data
# => 100

result.metadata
# => {
#      "meteorologists_reasoning" => "Accurate description of Rayleigh scattering under clear conditions.",
#      "meteorologists_score" => 100,
#      "physicists_reasoning" => "Correct as a plain statement of observed colour.",
#      "physicists_score" => 100,
#      "general_public_reasoning" => "Universally understood and correct.",
#      "general_public_score" => 100,
#      "final_score" => 100,
#      "final_reasoning" => "All reviewers agree the statement is factually correct."
#    }
```

Jury key names come from the roles chosen for that call. When you don't supply `juries` yourself, the roles vary between runs, and so do the metadata keys. Supply juries explicitly if you need stable keys.

## Configuration

`Scorer` has no module-specific settings. It is tuned against `deepseek-chat` and falls back to that model when no model is configured and DeepSeek has credentials.

```ruby
ActiveGenie::Scorer.call(text, criteria, config: { llm: { model: 'gpt-4o-mini' } })
```

See [Configuration](/reference/config) for the full set of options, and [Observability & errors](/reference/observability) for failure handling.

## Cost

- Supplying juries costs one LLM call.
- Leaving juries empty costs two calls: one to select the jury, one to score.

Passing `juries` explicitly halves the cost and makes the output keys deterministic. If you score many items against the same criteria, select the jury once and reuse it:

```ruby
juries = ActiveGenie::Lister.with_juries(sample_text, criteria).data

documents.map { |doc| ActiveGenie::Scorer.call(doc, criteria, juries) }
```

## Tips

- **Make the criteria specific.** "Evaluate quality" produces arbitrary numbers. "Evaluate medical accuracy, clarity, and clinical relevance" produces defensible ones.
- **Scores are comparative, not absolute.** A 78 means little on its own. Use `Scorer` to rank or threshold items evaluated under identical criteria rather than as a certificate against an absolute standard.
- **Supply juries for consistency.** Generated juries differ between runs, which moves the score. Fixed juries make scores comparable across a batch.
- **Don't over-trust small gaps.** An 84 and an 87 are not reliably distinguishable. Use [`Comparator`](/modules/comparator) when you need a confident head-to-head decision.
- **Thresholding works better than exact values.** A rule like "≥ 70 passes" holds up across runs, while a rule that expects exactly 85 will break.

## Examples

### Content quality

```ruby
ActiveGenie::Scorer.call(
  article_body,
  "Evaluate clarity, factual accuracy, and usefulness to a beginner audience",
  ["Editor", "Subject Matter Expert", "Beginner Reader"]
)
```

### Code review

```ruby
ActiveGenie::Scorer.call(
  diff,
  "Evaluate correctness, test coverage, and adherence to SOLID principles",
  ["Senior Software Engineer", "Security Engineer"]
)
```

### Compliance

```ruby
result = ActiveGenie::Scorer.call(
  marketing_copy,
  "Evaluate compliance with advertising standards and absence of unsubstantiated claims",
  ["Compliance Officer", "Legal Counsel"]
)

flag_for_review! if result.data < 70
```

# Ranker

Orders a list of items from best to worst against a criteria.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models, so the shape stays stable while the exact values change.

> [!WARNING]
> `Ranker` is the most expensive module by a wide margin. Its head-to-head stage grows quadratically with the number of items. Read [Cost](#cost) before ranking more than a handful.

## How it works

`Ranker` composes [`Scorer`](/modules/scorer) and [`Comparator`](/modules/comparator) into a tournament:

1. Scoring: a jury scores every item independently.
2. Variation elimination: the lowest scorer is dropped repeatedly until the spread of remaining scores falls below `config.ranker.score_variation_threshold`. That clears out obvious losers before any money goes into debates.
3. ELO rounds run while more than 15 items remain. Lower-tier items debate higher-tier ones, three debates each, and ELO ratings are updated. Lower tiers are relegated between rounds.
4. Free-for-all: every surviving pair debates head-to-head. A win is worth 3 points and a draw 1.

Scoring alone is cheap but coarse, while debates are expensive but decisive. The elimination stages exist so the debates get spent only where the ordering is still uncertain.

## Basic usage

```ruby
solutions = [
  "Uses modern design patterns with proper separation of concerns",
  "Implementation uses dependency injection for better testability",
  "Legacy code with tightly coupled components but working functionality"
]
criteria = "Evaluate code quality and software engineering best practices"

result = ActiveGenie::Ranker.call(solutions, criteria)

result.data
# => [
#      "Uses modern design patterns with proper separation of concerns",
#      "Implementation uses dependency injection for better testability",
#      "Legacy code with tightly coupled components but working functionality"
#    ]
```

`data` is your items, reordered best-first. Everything else is in `metadata`.

## Interface

### `.call(players, criteria, juries: [], config: {})`

Runs the full tournament. Alias for `.by_tournament`.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `players` | Array&lt;String, Hash&gt; | The items to rank. |
| `criteria` | String | What to rank against. |
| `juries` | Array&lt;String&gt; | Optional. Expert roles for the scoring stage. Generated per item when empty. |
| `config` | Hash | Per-call configuration overrides. See [Configuration](/reference/config). |

> [!IMPORTANT]
> `juries` is a **keyword** argument here. [`Scorer`](/modules/scorer) takes the same concept **positionally**. They are not interchangeable.
>
> ```ruby
> ActiveGenie::Scorer.call(text, criteria, juries)          # positional
> ActiveGenie::Ranker.call(items, criteria, juries: juries) # keyword
> ```

### `.by_tournament(players, criteria, juries: [], config: {})`

Identical to `.call`. Use it when you want the strategy named explicitly at the call site.

### `.by_elo(players, criteria, config: {})`

Runs one ELO round only: lower-tier items debate higher-tier ones, three debates each. Items must already carry scores, so you normally run this on the output of a scoring pass rather than on raw input.

### `.by_free_for_all(players, criteria, config: {})`

Every pair debates, with no scoring, elimination, or ELO stage beforehand. It gives the most thorough ordering available and costs the most. See [Cost](#cost).

### `.by_scoring(players, criteria, juries: [], config: {})`

Scores every item and sorts by score, without running any debates. It is the cheap approximation: good enough for a rough ordering, unreliable when items are closely matched.

> [!WARNING]
> `.by_scoring` does **not** return an `ActiveGenie::Result`. Unlike every other method in the library, it returns the internal batching structure from the concurrent scoring pass. Use `.call` or `.by_tournament` if you need the standard `Result` interface.

## Return value

`.call`, `.by_tournament`, `.by_elo`, and `.by_free_for_all` return an [`ActiveGenie::Result`](/introduction/quickstart#understanding-activegenie-result).

| Accessor | Type | Contents |
| :--- | :--- | :--- |
| `data` | Array | Your items, reordered best-first. Contents only, without scores or ranks. |
| `reasoning` | `nil` | Not populated by `Ranker`. |
| `metadata` | Array&lt;Hash&gt; | One hash per item, carrying its scores and tournament record. |

> [!IMPORTANT]
> There is no `players` key and no `statistics` key. `data` is a plain array, and rank is positional: `data[0]` is the winner.

Each entry in `metadata` has this shape:

```ruby
result.metadata.first
# => {
#      id: "8f14e45fceea167a5a36dedd4bea2543",
#      name: "Uses modern design",
#      content: "Uses modern design patterns with proper separation of concerns",
#      score: 85,
#      elo: 1245,
#      ffa_win_count: 2,
#      ffa_lose_count: 0,
#      ffa_draw_count: 0,
#      eliminated: nil,
#      ffa_score: 6,
#      sort_value: 6
#    }
```

`eliminated` is `nil` for surviving items, or `"variation_too_high"` / `"relegation_tier"` for items dropped during the elimination stages. Eliminated items still appear in the ordering, below the survivors.

To pair items with their scores:

```ruby
result.metadata.sort_by { |p| -p[:sort_value] }.each_with_index do |player, i|
  puts "#{i + 1}. #{player[:content]} (score: #{player[:score]}, elo: #{player[:elo]})"
end
```

## Configuration

| Setting | Default | Description |
| :--- | :--- | :--- |
| `config.ranker.score_variation_threshold` | `30` | Coefficient of variation the field must fall below. The lowest scorer is eliminated repeatedly until the spread drops under this value. Lower it to eliminate more aggressively and run fewer debates. |
| `config.llm.max_fibers` | `10` | How many debates run concurrently. |

```ruby
ActiveGenie::Ranker.call(items, criteria,
  config: { ranker: { score_variation_threshold: 20 }, llm: { max_fibers: 4 } })
```

`Ranker` has no model of its own. It inherits whatever `Scorer` and `Comparator` resolve to. See [Configuration](/reference/config) and [Observability & errors](/reference/observability).

## Cost

Almost all of the cost comes from the number of debates, so estimate it before putting `Ranker` in production.

| Stage | LLM calls |
| :--- | :--- |
| Scoring | 1 per item with `juries:` supplied, 2 per item without |
| ELO rounds | 3 debates per lower-tier item, per round, only while more than 15 items remain |
| Free-for-all | `n × (n - 1) / 2` debates across surviving items |

The free-for-all stage is quadratic, and it dominates everything else:

| Surviving items | Free-for-all debates |
| :---: | :---: |
| 4 | 6 |
| 8 | 28 |
| 15 | 105 |
| 30 | 435 |
| 50 | 1,225 |

A 4-item ranking without supplied juries costs roughly 14 calls. A 30-item ranking can exceed 500, and every one of those is a billed request.

To keep it manageable:

- Supply `juries:`. That halves the scoring stage and makes scores comparable across items.
- Lower `score_variation_threshold` so more items are eliminated before the quadratic stage.
- Use `.by_scoring` for large lists. Its cost is linear, and it is adequate when you only need a rough ordering or a shortlist.
- Run two passes on large inputs: shortlist with `.by_scoring`, then run `.call` on the top handful.

```ruby
# 200 candidates: score everything cheaply, rank only the finalists.
shortlist = candidates
  .map { |c| [c, ActiveGenie::Scorer.call(c, criteria, juries).data] }
  .max_by(10, &:last)
  .map(&:first)

ActiveGenie::Ranker.call(shortlist, criteria, juries: juries)
```

Requests run concurrently in batches of `config.llm.max_fibers`. Lower it if you hit provider rate limits. The library does not retry rate-limit responses automatically. See [Observability & errors](/reference/observability).

## Tips

- Rank comparable things. The criteria has to apply meaningfully to every item, and mixing categories produces arbitrary orderings.
- Trust the top and bottom more than the middle. Tournaments resolve clear winners and clear losers reliably, while adjacent middle ranks are close to noise.
- Supply juries if you want reproducibility. Generated juries vary per run, which moves scores, which moves the ordering.
- Two items is not a ranking. Use [`Comparator`](/modules/comparator) instead, which takes one call rather than several.
- Rank is positional. `data[0]` is the winner, and there is no `rank` key to look for.
- Run it in a background job. A large ranking takes minutes and hundreds of requests.

## Examples

### Ranking job candidates

```ruby
juries = ["Hiring Manager", "Senior Engineer", "Technical Recruiter"]

ActiveGenie::Ranker.call(
  candidate_summaries,
  "Evaluate fit for a senior backend role: depth of experience, systems design, and communication",
  juries: juries
)
```

### Cheap ordering of a large list

```ruby
ActiveGenie::Ranker.by_scoring(articles, "Evaluate depth and originality")
```

### Exhaustive ranking of a small set

```ruby
ActiveGenie::Ranker.by_free_for_all(
  ["Variant A", "Variant B", "Variant C", "Variant D"],
  "Which headline would get the most clicks from software developers?"
)
# 6 debates
```

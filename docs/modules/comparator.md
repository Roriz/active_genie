# Comparator

Compares two options against a criteria and returns the winner.

> [!NOTE]
> Outputs on this page are illustrative. LLM responses vary between runs and models, so the shape stays stable while the exact values do not.

## How it works

`Comparator` stages a structured debate between the two players and has an impartial judge decide:

1. Player A presents its strengths against the criteria.
2. Player B presents its strengths against the criteria.
3. Player A responds with counter-arguments.
4. Player B responds with counter-arguments.
5. Both give closing arguments.
6. An impartial judge picks a winner.

There is no draw. The judge always returns one of the two players.

The number of rounds and their structure may change between versions as prompts are tuned, so depend on the winner rather than on the debate transcript.

## Basic usage

```ruby
player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Comparator.call(player_a, player_b, criteria)

result.data
# => "Implementation uses dependency injection for better testability"

result.reasoning
# => "Player A's dependency injection allows components to be replaced and tested in
#     isolation. Player B's coverage is valuable but the tight coupling makes future
#     changes riskier."
```

## Interface

### `.call(player_a, player_b, criteria, config: {})`

Runs a debate. Alias for `.by_debate`.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `player_a` | String, Hash | The first option. |
| `player_b` | String, Hash | The second option. |
| `criteria` | String | What the judge should evaluate against. |
| `config` | Hash | Per-call configuration overrides. See [Configuration](/reference/config). |

### `.by_debate(player_a, player_b, criteria, config: {})`

Identical to `.call`. Use it when you want the strategy named explicitly at the call site.

### `.by_fight(player_a, player_b, criteria, config: {})`

A variant tuned for combat scenarios: martial artists, heroes, characters. It takes the same parameters and returns the same shape as `.call`, but the players take turns exchanging moves rather than arguing, and the judge scores the exchange.

```ruby
player_a = "Master Crane, a graceful fighter whose Crane Kung Fu relies on lightness, precision, and redirecting an opponent's momentum."
player_b = "Iron Ox, a powerful brawler whose Ox Bull Charge style uses immense strength and mass to overwhelm opponents."
criteria = "Determine the winner of a one-on-one duel based on skill, strategy, and adaptability."

result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)
result.data
# => "Master Crane, a graceful fighter whose Crane Kung Fu relies on lightness, ..."
```

The turn count and structure may change between versions.

## Return value

Returns an [`ActiveGenie::Result`](/introduction/quickstart#understanding-activegenie-result).

| Accessor | Type | Contents |
| :--- | :--- | :--- |
| `data` | String or Hash | The winning player, returned exactly as you passed it in. It is not a hash of results. |
| `reasoning` | String | The judge's explanation for the decision. |
| `metadata` | Hash | The full debate transcript, keyed by strings. |

> [!IMPORTANT]
> `result.data` is the winner itself, not a wrapper. There is no `loser` key. The loser is whichever player you passed that `data` doesn't equal.

```ruby
result = ActiveGenie::Comparator.call(player_a, player_b, criteria)

winner = result.data
loser  = (winner == player_a ? player_b : player_a)
```

The `metadata` hash carries each stage of the debate:

```ruby
result.metadata.keys
# => ["player_a_sell_himself", "player_b_sell_himself", "player_a_arguments",
#     "player_b_counter", "player_a_adherence_score", ...,
#     "impartial_judge_winner", "impartial_judge_winner_reasoning"]
```

Treat `metadata` as debugging output. Its keys track the prompt and can change between versions.

## Configuration

`Comparator` has no module-specific settings. It is tuned against `claude-haiku-4-5` and falls back to it when no model is configured and Anthropic has credentials.

```ruby
ActiveGenie::Comparator.call(player_a, player_b, criteria,
  config: { llm: { model: 'gpt-4o-mini' } })
```

See [Configuration](/reference/config) for the full set of options, and [Observability & errors](/reference/observability) for failure handling.

## Cost

Each comparison uses one LLM call. The debate happens within a single structured response, so the cost stays around one request regardless of how many rounds the prompt runs.

`Ranker` composes `Comparator` and issues many comparisons, so read the [Ranker](/modules/ranker) page before ranking large lists.

## Tips

- Describe each player in detail. The more detail tied to the criteria, the better the decision. Unrelated characters or context dilute the comparison.
- Describe what actually drives the criteria. If you are comparing phones on style, write about design, colours, and materials instead of battery specs.
- Be specific in the criteria. Where does the comparison take place? Are there constraints, such as fitting in one hand, working in rain, or allowing no weapons?
- Don't parse the transcript. `metadata` is for debugging. Build on `data` and `reasoning`, which are stable.
- For fights, describe capabilities concretely. What are each fighter's top moves, how fast and destructive are they, and what are the drawbacks? Vague fighters produce arbitrary winners.

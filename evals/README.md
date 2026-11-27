# ActiveGenie's own evals

These are the gem's evals. They're built the way any app builds its evals, with the engine the gem
ships (`ActiveGenie::Eval`). Every change to `lib/` is measured against a frozen baseline of `main`.

**The method is in [the app guide](../lib/active_genie/eval/templates/README.md)**: running an eval,
reading the report, the good practices, writing an eval, the row format, the graders and labeling.
`rake active_genie:eval:install` writes that same guide into an app's `evals/`. This page covers only
what is specific to the gem.

The Ranker is out of scope. Its live tests stay in `test/e2e/ranker`.

```shell
bundle exec rake active_genie:eval:check                          # free: every eval, dataset and gold
bundle exec rake active_genie:eval EVAL=all                       # the dev pools of all evals, then a summary
bundle exec rake active_genie:eval EVAL=comparator MODE=full      # one eval, every case
bundle exec rake prompts:check                                    # free: lints lib/**/*.prompt.md and the function JSON
```

## The evals

| Eval | Method | Grader | Cases (dev + test) |
|---|---|---|---|
| `extractor` | `Extractor.data` and `with_explanation`, as two variants | `fields` | 14 + 60 |
| `extractor_with_litote` | `Extractor.with_litote` | `fields` | 6 + 30 |
| `comparator` | `Comparator.by_debate` and `by_fight`, as two variants | `winner`, both orders | 20 + 39 |
| `lister_with_feud` | `Lister.with_feud` | `list` | 10 + 30 |
| `lister_with_juries` | `Lister.with_juries` | `list` | 10 |
| `scorer_by_jury_bench` | `Scorer.by_jury_bench` | `band`, bias pairs as twin rows | 20 + 25 |

The headline is the mean of the eight rates in the `EVAL=all` summary (the extractor and the
comparator count once per variant), so an eval with many cases doesn't drown out the others.

- `config.yml` pins the dev model (`gpt-6.1-terra`) and the judge (`claude-sonnet-5-5`).
- Its `watch:` covers the modules the evals measure, not the eval engine. Changing the engine doesn't
  start fresh, paid runs.
- The four release models run in the `Eval` workflow (`.github/workflows/benchmark.yml`, triggered by
  hand), with `PROVIDER=` and `MODEL=`.
- The 80 cases migrated from `test/e2e` are dev only, because the prompts were written alongside them.

## Where the cases come from

External data (datasets, fetched files) and gems can use any clear open license: MIT, Apache-2.0,
BSD, CC BY and the like. The one license question is whether using it would make ActiveGenie users
change or care about their own licenses; the project should stay as free and open as possible. So
data with no stated license, non-commercial (NC) terms, or share-alike/copyleft terms that would
reach users is still out. Credit the source: keep a `NOTICE.md` next to the data that is used, as
[hh-rlhf's](comparator/sources/hh_rlhf/NOTICE.md) does.

When no openly licensed source fits, the cases are written here instead. They're drafted
(`"status": "draft"`), labeled by two blind passes, and checked with
`rake active_genie:eval:label EVAL=<name>`. The extractor evals started from CUAD
(CC BY 4.0) and CondaQA (Apache-2.0), and both were replaced with drafted cases under an earlier
MIT-only rule. Both are allowed again (see
[NEXT_FOCUS.md](NEXT_FOCUS.md#data-for-the-next-phases-license-check-2026-11-17)).

- **comparator**: the test cases come from [hh-rlhf](comparator/sources/hh_rlhf/NOTICE.md) (MIT).
  Each one is a conversation, two possible next replies, and a crowdworker's pick of the more helpful
  one. Those picks are noisy, so `comparator/sources/hh_rlhf/build.rb` adds them as drafts with
  `"on_disagreement": "drop"`. A case is kept only when both blind passes pick the same reply as the
  crowdworker. Pass B sees the replies in the opposite order to pass A, so a labeler's position bias
  can't keep a case. Half the drafts have the picked reply as the longer one and half as the shorter
  one (`tags.length`), so preferring length doesn't pay. Both variants run every case, so `by_debate`
  and `by_fight` are compared head to head on the same cases.
- **scorer_by_jury_bench**: no source with multi-rater scores is used yet (the openly licensed
  candidates in NEXT_FOCUS.md are still to check), so the test cases are drafted. There are 12
  calibration cases, including texts whose polish and quality disagree. There are also 18 bias
  pairs as twin rows, three for each of six biases: verbosity, authority, bandwagon, injection,
  identity and distraction. Both texts of a pair share their juries (`context.shared` in `eval.rb`),
  so the gap comes from the change alone. 25 of the 30 passed labeling; five wait in the queue. The
  test cases leave `juries` out, so the scorer picks its own with `Lister.with_juries`: that is how
  `lister_with_juries` is judged, by its effect on the scorer.
- **lister_with_feud**: no source with real crowd answer counts is used yet either (ProtoQA is a
  candidate, see NEXT_FOCUS.md), so the test cases are drafted Family Feud questions whose top
  answers are near-certain common knowledge. Each gold asks for one of the crowd's top answers in the first two items (`top_k_any`), and at least three groups
  of the usual answers (`min_groups`). 18 of the 30 also forbid a few correct but unusual answers
  (`no_item`), which catches listing like an expert instead of like the crowd.

## Tests

The engine is covered by `test/unit/app_eval/` (part of `rake test:unit`). That includes an offline
run → baseline → regression cycle, and a test that runs `check` on this folder, so broken data fails
CI.

## Known issues and what's next

[NEXT_FOCUS.md](NEXT_FOCUS.md) sorts the known issues by the Three Gulfs (comprehension,
specification, generalization) and lists the next steps. It also has the license check of the data
planned for later.

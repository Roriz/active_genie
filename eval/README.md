# ActiveGenie eval

A golden-set eval for the Comparator, Extractor, Lister and Scorer modules. It replaces the old
`test/e2e` benchmark. The expected answers are data you build, version and audit, and every change to
`lib/` is measured against a frozen baseline of `main`, with statistics that tell a real change apart
from model noise.

The Ranker is out of scope; its live tests stay in `test/e2e/ranker`.

## The loop

```shell
bundle exec rake eval:check                 # free: data integrity + prompt lint
bundle exec rake eval:quick                 # prints the cost of what isn't cached yet
YES=1 bundle exec rake eval:quick           # runs it -> GO / LOOK / STOP
```

1. Edit a prompt or a method in `lib/`. A variant is simply your working tree: there is no prompt
   override, so the eval always tests the real code path.
2. `eval:quick` runs the dev pool on the dev model and compares each case with the baseline.
   - **STOP**: a canary (a case the baseline always gets right) broke.
   - **LOOK**: something else broke, or a call errored.
   - **GO**: nothing broke.
3. Before merging, `YES=1 bundle exec rake eval:full` runs every case and reports the weighted pass
   rate with a CI, the delta against the baseline with its CI and an exact McNemar p-value, and the
   cases that broke or got fixed.
4. After merging to `main`, promote the run to the new baseline:
   `YES=1 REPEAT=3 bundle exec rake eval:full && bundle exec rake eval:save`.
   `REPEAT=3` runs everything three times to measure the noise floor (how often a case flips between
   identical runs). `eval:save` refuses a run with missing or errored cases, or one whose `lib/` has
   uncommitted changes.

Outputs are cached per case in `eval/runs/<provider>-<model>-<lib hash>/r<n>/`, so nothing is paid
for twice: re-running only calls the cases that are new, or that errored last time. A change to
any file in `lib/` changes the hash and starts a fresh run. `rake eval:report` re-prints a report
from the cache for free.

## Commands

| Task | Cost | What it does |
|---|---|---|
| `eval:check` | free | Validates cases, gold and pools; lints `lib/**/*.prompt.md` and function JSON; lists what changed in `lib/` vs `main` |
| `eval:status` | free | Cases per cell, pool and role; which release models have a baseline |
| `eval:quick` | paid | Dev pool: up to 3 hard cases + 2 canaries per cell once roles exist (`ALL_DEV=1` for the whole pool) |
| `eval:full` | paid | Every case. `REPEAT=n` for replicates |
| `eval:report` | free | Re-prints the report from cached outputs (`MODE=quick\|full`) |
| `eval:save` | free | Promotes the complete run to `eval/baselines/<provider>-<model>/` and, for the dev model, assigns dev-pool roles |

Environment: `PROVIDER` and `MODEL` (default: the dev model in `config.json`), `CELLS=a,b` to run a
subset, `YES=1` to spend money, `BY=name` for `eval:save`, `FORCE=1` to save from a dirty `lib/`.

## Models

`config.json` pins the models. Moving to a newer model is a deliberate change: update `config.json`
and save a new baseline.

| Role | Provider | Model | Runs on |
|---|---|---|---|
| Dev loop | `codex` | `gpt-6.1-terra` | your local Codex login (`codex exec`) |
| Judge | `claude-code` | `claude-sonnet-5-5` | your local Claude login, `eval-judge` subagent |
| Release | `codex`, `claude-code`, `google`, `deepseek` | see `config.json` | local logins for the first two, APIs for the rest |

### Local CLIs instead of the OpenAI and Anthropic APIs

OpenAI and Claude models run through local CLIs logged in with your own subscriptions, not the
provider APIs. `eval/lib/genie_eval/transports.rb` swaps only the transport behind ActiveGenie's
`UnifiedProvider.function_calling`. The library still builds its own prompts and function schemas,
so the eval still tests your working tree.

- **`codex`** runs `codex exec --output-schema` in a read-only sandbox in an empty directory.
- **`claude-code`** runs `claude -p` with a subagent from [`.claude/agents/`](../.claude/agents/):
  `eval-model` answers ActiveGenie's function call; `eval-judge` grades free text (cached under
  `eval/runs/_judge/`). Tools that act are disallowed.
- `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` are removed from the CLI's environment, so a CLI can
  never fall back to API billing. Log in once with `codex login` and `claude /login`.
- The CLIs expose no logprobs, so modules take their non-logprob path (the debate judge's own
  winner field, the jury's own final score). Codex also adds its agent instructions to every call
  (about 17k input tokens), so token counts are not comparable with API runs.
- Results are kept apart by system name (`codex-…`, `claude-code-…`): a CLI baseline is never
  compared with an API run of the same model.

`PROVIDER=openai` or `PROVIDER=anthropic` still use the APIs if you need them. Add a model's price
under `usd_per_million_tokens` to get dollar estimates for API runs.

The `Eval` GitHub workflow (triggered manually) runs only the API-billed release models, because CI
has no CLI logins.

## Cells, pools and roles

A **cell** is one public method, such as `extractor.with_litote`. Cells have equal weights: the
headline number is the mean of the cell pass rates, so a cell with many cases doesn't drown out the
others.

Each case is in one **pool**: `dev` (what you iterate against) or `test` (only for `eval:full`, so
prompts are not tuned to it). The 80 cases migrated from `test/e2e` are dev-only, because the prompts
were written alongside them. Test-pool cases come from public datasets and generated cases in later
phases.

`eval:save` gives each dev case a **role** from the baseline: `canary` if it passed in every
replicate, `hard` if it didn't.

## Reading the report

- `rate` per cell and the weighted rate with a stratified bootstrap CI.
- `MDE`: the smallest change this many cases can reliably detect. With 30 cases per cell it is
  about 22 points per cell and 8 overall; a smaller delta is not evidence of anything.
- `delta`, `broke`, `fixed`, `p`: the paired comparison with the baseline on the same cases.
- Extractor fields get one of five outcomes: correct, wrong value, omission, correct abstention or
  invention. The field CI resamples whole cases, because fields of one document move together.
- Comparator cases run in both orders; a case passes only if both orders pick the gold winner, and
  the report shows how often the winner is the same in both orders.

## Data

See [FORMAT.md](FORMAT.md) for the case, gold and pool formats. Datasets are committed only when their
license allows it; otherwise a fetch script with a pinned checksum is committed instead.

## Tests

The eval's own code is covered by `test/unit/eval/` (part of `rake test:unit`), including an
offline run -> baseline -> regression cycle with a stubbed model.

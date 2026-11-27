# Tests

Notes for agents working in `test/`. The suite is Minitest with WebMock. Each layer has its own
`test_helper.rb`.

## Layers and how to run them

| Layer | Path | Command | Network / cost |
|---|---|---|---|
| Unit | `test/unit/` | `bundle exec rake test:unit` | None. WebMock blocks every real request. |
| Integration | `test/integration/` | `bundle exec rake test:integration` | Runs `rails new` and `bundle install` in `/tmp/latest_rails_app`. Slow, needs network, no LLM calls. |
| E2E | `test/e2e/` | `PROVIDER_NAME=openai bundle exec rake test:e2e` | Real LLM calls. Needs that provider's key and **costs money**. |

Run unit tests while you work. CI runs unit and integration on every PR (`.github/workflows/`).
Only run e2e when the user asks for it, because every run is billed to their account.

Run a single file or test through rake, not with bare `ruby`:

```sh
bundle exec rake "test[test/unit/ranker/elo_test.rb]"
bundle exec rake "test[test/unit/ranker/elo_test.rb:108]"   # the test at that line
```

The reason is API keys. Provider configs fall back to `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`,
`GEMINI_API_KEY`, `DEEPSEEK_API_KEY` and `PROVIDER_NAME` from the environment
(`lib/active_genie/configs/providers/`). The `test:reset_env` task in `lib/tasks/test.rake` clears
the four key variables before unit and integration runs. A bare
`ruby -Itest test/unit/providers/unified_provider_test.rb` skips that step, so a real key from your
shell changes which provider gets picked. Tests then fail with WebMock "unregistered request"
errors that look like bugs but aren't. `reset_env` does not clear `GENERATIVE_LANGUAGE_GOOGLE_API_KEY`
or `PROVIDER_NAME`. If either is set in your shell, unset it before you trust a provider-selection
failure.

## Fake the provider at the HTTP boundary

Unit tests call the real public API, for example `ActiveGenie::Comparator.by_debate`, and stub only
the provider's HTTP endpoint. The internal classes (comparator, providers, response parsing,
retries) then run against each other for real, and that is where the bugs in this gem show up.
A test that stubs those classes passes even when they no longer fit together.

The usual pattern (`test/unit/comparator/debate_test.rb`):

```ruby
stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
  status: 200,
  body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
)

result = ActiveGenie::Comparator.by_debate(@player_a, @player_b, @criteria,
                                           config: { providers: { openai: { api_key: 'openai_secret' } } })

assert_requested(:post, 'https://api.openai.com/v1/chat/completions') { |req| ... }
assert_equal 'Player A content', result.data
```

What this example shows:

- **Pass a fake key via `config:`.** Don't depend on the environment or on global configuration,
  so the test behaves the same on every machine and in CI.
- **Assert both sides.** Check the request the gem sent (`assert_requested` on the prompt, tools and
  model) and the `Result` it returned. Assertions that only read back the stub's own data test
  nothing.
- **Cover each provider the module supports.** The module tests repeat the same case for OpenAI,
  Anthropic, Google and DeepSeek, because each provider has a different request and response shape.

## Fixtures

`test/unit/fixtures/<module>-<provider>.json` (for example `scorer-google.json`) are full,
real-shaped HTTP response bodies from each provider. Reuse them before you write a new one.
Provider APIs change between versions, and every stubbed body is something to update when they do,
so fewer fixtures means a cheaper migration. When a test needs a specific answer (a winner, a
score, an empty list), build a small body in a private helper in that test file, as
`stub_judge` in `test/unit/ranker/elo_test.rb` and `openai_tool_response` in
`test/unit/ranker/scoring_test.rb` do. Keep those bodies to the fields the parser reads. To route
several calls in one test, match on the request body with `.with(body: /function_name/)` (see the
`setup` in `test/unit/ranker/tournament_test.rb`).

E2E tests load realistic inputs (not responses) from `test/e2e/fixtures/` via `load_fixture`.

## Where the suite stubs internal code

Some tests stub internal ActiveGenie code instead of HTTP:

- `test/unit/providers/unified_provider_test.rb` stubs `*Provider.new`. That is the class under
  test's direct collaborator, and the behaviour under test is which provider gets picked.
- `test/unit/providers/{openai,google}_provider_test.rb` stub the provider's own `request` method
  to feed it parsed bodies.
- The logprobs tests in `comparator/debate_test.rb`, `scorer/jury_bench_test.rb` and
  `extractor/with_explanation_test.rb` stub `UnifiedProvider.function_calling`.
- `ranker/scoring_test.rb` stubs `Lister::Juries.call` in two tests.

Treat these as existing exceptions, not as the pattern to follow. For new tests, stub HTTP. Stub an
internal seam only when the behaviour can't be reached through HTTP, or when the seam itself is the
thing under test. If you do, pick the seam closest to the network and leave a one-line comment
saying why.

## Scope and layout

- Mirror `lib/`: `lib/active_genie/ranker/elo.rb` is tested in `test/unit/ranker/elo_test.rb`.
  The one exception is `lib/active_genie/eval/`, which is tested in `test/unit/app_eval/`. Put a
  new test in the file for the class whose behaviour it checks. A failure then points at one class.
- Test a class's own responsibility and assume its collaborators work. For example, a Ranker test
  checks ordering and scoring, not whether the debate prompt is right. `debate_test.rb` covers that.
- Include the failure paths that callers rely on: empty or `nil` provider answers, missing keys,
  unknown providers and retries. These are the cases where real provider responses differ from the
  happy path.
- `test/unit/app_eval/` never calls a model. It uses tmp dirs and fake answerers such as
  `FakeAnswerer` in `app_eval_test.rb`, and resets `Eval` in `teardown`. Keep that true there.
- If you override `teardown`, call `super`. `webmock/minitest` resets its stubs in it (see
  `test/unit/configs/providers_config_test.rb`).

Before you finish, run `bundle exec rubocop`. It covers `test/` and includes rubocop-minitest.

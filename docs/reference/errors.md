# Errors

Every error ActiveGenie raises inherits `ActiveGenie::Error`, which inherits `StandardError`, and has
a stable code. Codes are never reused, so you can log, alert and group failures by them. Each
message says what went wrong, with the values involved, then how to fix it, then links its entry on
this page:

```text
No provider has an API key, so ActiveGenie has no model to call.

How to fix:
  Set the API key of at least one provider, ...

Docs: https://activegenie.ai/reference/errors#ag-e001
```

```ruby
begin
  ActiveGenie::Scorer.call(text, criteria)
rescue ActiveGenie::ProviderTransientError => e
  RetryLaterJob.perform_later(text, criteria) # rate limits and outages, after every retry
rescue ActiveGenie::Error => e
  Rails.logger.error(code: e.code, error: e.message)
  raise
end
```

`e.code` (and `ActiveGenie::ProviderTransientError.code`) returns the code, for example `"AG-E102"`.
The codes come in three groups: `AG-E0xx` for configuration, `AG-E1xx` for provider calls and
`AG-E2xx` for the eval engine (`ActiveGenie::Eval`). Every eval error also inherits
`ActiveGenie::Eval::Error`.

| Code | Class | Raised when |
| :--- | :--- | :--- |
| [AG-E001](#ag-e001) | `WithoutAvailableProviderError` | No provider has an API key. |
| [AG-E002](#ag-e002) | `InvalidProviderError` | A provider name ActiveGenie can't call. |
| [AG-E003](#ag-e003) | `InvalidModelError` | `config.llm.model` names a model no credentialed provider runs. |
| [AG-E004](#ag-e004) | `InvalidLogOutputError` | `config.log.output` doesn't respond to `call`. |
| [AG-E005](#ag-e005) | `InvalidLogScopeError` | `add_observer` got a scope that isn't a Hash. |
| [AG-E006](#ag-e006) | `CallNotImplementedError` | A `BaseModule` subclass doesn't define `call`. |
| [AG-E101](#ag-e101) | `ProviderUnknownError` | The provider answered with an HTTP error a retry won't fix. |
| [AG-E102](#ag-e102) | `ProviderTransientError` | A 408, 429 or 5xx still failing after every retry. |
| [AG-E103](#ag-e103) | `ProviderConnectionError` | The network failed on every attempt. |
| [AG-E104](#ag-e104) | `RefusalError` | The provider declined the request or blocked the answer. |
| [AG-E105](#ag-e105) | `InvalidResponseError` | The answer has no usable tool call, text or JSON. |
| [AG-E106](#ag-e106) | `TruncatedResponseError` | The answer was cut off at the token limit. |
| [AG-E201](#ag-e201) | `Eval::ConfigMissingError` | `evals/config.yml` doesn't exist. |
| [AG-E202](#ag-e202) | `Eval::ConfigSyntaxError` | `evals/config.yml` isn't valid YAML. |
| [AG-E203](#ag-e203) | `Eval::DefineOutsideLoadError` | `Eval.define` ran outside an `evals/<name>/eval.rb`. |
| [AG-E204](#ag-e204) | `Eval::EvalNameMismatchError` | An `eval.rb` defines an eval not named after its folder. |
| [AG-E205](#ag-e205) | `Eval::UnknownEvalError` | `EVAL=` names an eval that doesn't exist. |
| [AG-E206](#ag-e206) | `Eval::InvalidEvalNameError` | A new eval's name isn't snake_case. |
| [AG-E207](#ag-e207) | `Eval::InvalidVariantNameError` | A variant's name isn't snake_case. |
| [AG-E208](#ag-e208) | `Eval::VariantWithoutBlockError` | A variant has no block. |
| [AG-E209](#ag-e209) | `Eval::MissingCallBlockError` | An `eval.rb` has no `call` block. |
| [AG-E210](#ag-e210) | `Eval::UnknownGraderError` | An `eval.rb` names a grader that doesn't exist. |
| [AG-E211](#ag-e211) | `Eval::UnknownCheckError` | A `fields` gold uses a check that doesn't exist. |
| [AG-E212](#ag-e212) | `Eval::UnknownListCheckError` | A `list` gold uses a check type that doesn't exist. |
| [AG-E213](#ag-e213) | `Eval::UnknownModeError` | `MODE=` is not `quick` or `full`. |
| [AG-E214](#ag-e214) | `Eval::MissingGoldError` | A graded case has no gold. |
| [AG-E215](#ag-e215) | `Eval::InvalidJsonlError` | A `.jsonl` line isn't valid JSON. |
| [AG-E216](#ag-e216) | `Eval::JudgeConfigMissingError` | A case needs the judge and `evals/config.yml` pins none. |
| [AG-E217](#ag-e217) | `Eval::MalformedJudgeAnswerError` | The judge answered in the wrong shape. |
| [AG-E218](#ag-e218) | `Eval::InvalidLabelPassError` | A label's pass is not `a` or `b`. |
| [AG-E219](#ag-e219) | `Eval::CustomGraderLabelingError` | Labeling an eval with a custom grader. |
| [AG-E220](#ag-e220) | `Eval::InvalidWinnerLabelError` | A winner label is not `a`, `b` or `either`. |
| [AG-E221](#ag-e221) | `Eval::InvalidListLabelError` | A list label is not an array. |
| [AG-E222](#ag-e222) | `Eval::NoRunToBaselineError` | Saving a baseline with no run for the current code. |
| [AG-E223](#ag-e223) | `Eval::IncompleteRunError` | Saving a baseline from a run with missing or errored cases. |
| [AG-E224](#ag-e224) | `Eval::UnjudgedRunError` | Saving a baseline with cases waiting for the judge. |
| [AG-E225](#ag-e225) | `Eval::DirtyWorktreeError` | Saving a baseline with uncommitted changes to watched files. |

## Configuration

### AG-E001 WithoutAvailableProviderError {#ag-e001}

`ActiveGenie::WithoutAvailableProviderError`

**Raised when** a module is called and no provider has an API key.

**How to fix:** set the key of at least one provider, from its environment variable
(`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` or `DEEPSEEK_API_KEY`) or in the config. See
[choosing a provider](/reference/config#choosing-a-provider).

```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV.fetch('OPENAI_API_KEY')
end
```

### AG-E002 InvalidProviderError {#ag-e002}

`ActiveGenie::InvalidProviderError`

**Raised when** `config.providers.default`, the `PROVIDER_NAME` environment variable or
`config.providers.add` names a provider ActiveGenie can't call. It can call `openai`, `google`,
`anthropic` and `deepseek`.

**How to fix:** use one of those names. To call another OpenAI-compatible API, such as a gateway,
replace a built-in provider's config with `config.providers.add(:openai, MyGatewayConfig)`.

### AG-E003 InvalidModelError {#ag-e003}

`ActiveGenie::InvalidModelError`

**Raised when** `config.llm.model` is set, no provider is named next to it, and no provider with an
API key recognises the model. ActiveGenie picks the provider from the model name: `gpt` for OpenAI,
`claude` for Anthropic, `gemini` for Google and `deepseek` for DeepSeek.

**How to fix:** set the provider next to the model, for any other name (`o3`, a fine-tune, a gateway
model):

```ruby
ActiveGenie.configure do |config|
  config.providers.default = 'openai'
  config.llm.model = 'o3'
end
```

### AG-E004 InvalidLogOutputError {#ag-e004}

`ActiveGenie::InvalidLogOutputError`

**Raised when** `config.log.output` is set to something that doesn't respond to `call`.

**How to fix:** set it to a lambda, a Proc or any object with a `call(log)` method, for example
`config.log.output = ->(log) { Rails.logger.info(log) }`.

### AG-E005 InvalidLogScopeError {#ag-e005}

`ActiveGenie::InvalidLogScopeError`

**Raised when** `config.log.add_observer` gets a `scope:` that isn't a Hash.

**How to fix:** pass the log fields an entry must match, such as `scope: { code: :llm_usage }`, or
leave `scope:` out to observe every entry. See [observers](/reference/observability).

### AG-E006 CallNotImplementedError {#ag-e006}

`ActiveGenie::CallNotImplementedError`

**Raised when** a subclass of `ActiveGenie::BaseModule` is called but doesn't define `call`.

**How to fix:** define `call`. It sends its messages through
`ActiveGenie::Providers::UnifiedProvider.function_calling` and returns an `ActiveGenie::Result`;
`lib/active_genie/comparator/debate.rb` is a complete example.

## Provider calls

`ProviderTransientError` subclasses `ProviderUnknownError`, and `TruncatedResponseError` subclasses
`InvalidResponseError`, so a rescue of the parent also catches the child.

### AG-E101 ProviderUnknownError {#ag-e101}

`ActiveGenie::ProviderUnknownError`

**Raised when** the provider answers with an HTTP error that a retry won't fix: any non-2xx status
but 408, 429 and 5xx. It is not retried. The message carries the status and the provider's own body,
for example `OpenAI answered HTTP 401 for model "gpt-5": {"error": ...}`.

**How to fix:** the message has a hint for the status:

- **401:** the provider refused the API key. Check `config.providers.<name>.api_key` or its
  environment variable.
- **402:** the account is out of credits.
- **403:** the key has no access to this model or endpoint.
- **404:** the provider doesn't know the model or URL. Check `config.llm.model` and, for a gateway,
  `config.providers.<name>.api_url`.
- **400 and others:** the provider's body names the problem.

### AG-E102 ProviderTransientError {#ag-e102}

`ActiveGenie::ProviderTransientError`

**Raised when** a rate limit (429), request timeout (408) or server error (5xx) is still failing
after every retry.

**How to fix:** wait longer between retries with `config.llm.max_retries` and
`config.llm.retry_delay` (see [retries](/reference/observability#retries)), or retry the call later
from a background job.

### AG-E103 ProviderConnectionError {#ag-e103}

`ActiveGenie::ProviderConnectionError`

**Raised when** the network fails on every attempt: the connection is refused, or opening it
(`Net::OpenTimeout`) or reading the answer (`Net::ReadTimeout`) times out. `e.cause` is the last
network error.

**How to fix:** check that the host can reach the provider (proxy, firewall, DNS) and, for a gateway,
its `api_url`. A model that answers slowly needs a longer `config.llm.read_timeout` (default 60
seconds); `config.llm.open_timeout` covers opening the connection (default 10 seconds).

### AG-E104 RefusalError {#ag-e104}

`ActiveGenie::RefusalError`

**Raised when** the provider declines the request or blocks the answer: an OpenAI `refusal` or
`content_filter`, an Anthropic `refusal` stop reason, or a Google prompt or answer blocked by its
safety filters. The message names the category or block reason. It is not retried.

**How to fix:** a retry of the same input gets the same refusal. Check the input for content the
provider won't process, reword the criteria, or send these inputs to another provider with
`config.providers.default`.

### AG-E105 InvalidResponseError {#ag-e105}

`ActiveGenie::InvalidResponseError`

**Raised when** the provider answers, but not with a usable result: no tool call or text, tool
arguments that aren't JSON, or a body that isn't JSON. It is not retried.

**How to fix:** this is usually a one-off from the model, so retry the call, ideally from a
background job. If it keeps happening, the model doesn't follow function calling reliably; pick
another one with `config.llm.model`.

### AG-E106 TruncatedResponseError {#ag-e106}

`ActiveGenie::TruncatedResponseError`

**Raised when** the answer was cut off at the token limit (Anthropic `max_tokens`, OpenAI `length`,
Google `MAX_TOKENS`), so it is incomplete.

**How to fix:** for Anthropic, raise `config.llm.max_tokens` (default 16000). OpenAI, Google and
DeepSeek get no token limit from ActiveGenie, so the model hit its own output limit: send a shorter
input, or pick a model with a larger output limit.

## Evals

These come from `ActiveGenie::Eval` and the `active_genie:eval` rake tasks, which print the message
without a backtrace. See the [evals guide](/guides/evals).

### AG-E201 ConfigMissingError {#ag-e201}

`ActiveGenie::Eval::ConfigMissingError`

**Raised when** `evals/config.yml` doesn't exist under the app root.

**How to fix:** run `rake active_genie:eval:install` from the app root. It writes `evals/config.yml`,
`evals/README.md` and `evals/.gitignore`, and never overwrites a file.

### AG-E202 ConfigSyntaxError {#ag-e202}

`ActiveGenie::Eval::ConfigSyntaxError`

**Raised when** `evals/config.yml` isn't valid YAML.

**How to fix:** fix the line the YAML error names. The file `rake active_genie:eval:install` writes is
the reference.

### AG-E203 DefineOutsideLoadError {#ag-e203}

`ActiveGenie::Eval::DefineOutsideLoadError`

**Raised when** `ActiveGenie::Eval.define` runs anywhere but in an `evals/<name>/eval.rb` that
`ActiveGenie::Eval.load!` reads.

**How to fix:** put the `define` block in `evals/<name>/eval.rb`, and don't require or load that file
yourself. The rake tasks load every `evals/*/eval.rb`.

### AG-E204 EvalNameMismatchError {#ag-e204}

`ActiveGenie::Eval::EvalNameMismatchError`

**Raised when** `evals/<folder>/eval.rb` defines an eval with another name.

**How to fix:** name the eval after its folder, or move the file to the folder of its name.

### AG-E205 UnknownEvalError {#ag-e205}

`ActiveGenie::Eval::UnknownEvalError`

**Raised when** `EVAL=` (or `ActiveGenie::Eval.fetch`) names an eval that has no
`evals/<name>/eval.rb`. The message lists the evals there are.

**How to fix:** pass one of those names, or start the eval with `rake "active_genie:eval:new[name]"`.

### AG-E206 InvalidEvalNameError {#ag-e206}

`ActiveGenie::Eval::InvalidEvalNameError`

**Raised when** a new eval gets a name that isn't snake_case, such as `Ticket Router`.

**How to fix:** use lowercase letters, digits and underscores, starting with a letter:
`rake "active_genie:eval:new[ticket_router]"`.

### AG-E207 InvalidVariantNameError {#ag-e207}

`ActiveGenie::Eval::InvalidVariantNameError`

**Raised when** a `variant` in `eval.rb` gets a name that isn't snake_case.

**How to fix:** use lowercase letters, digits and underscores, starting with a letter:
`variant :fast_path do |input, context| ... end`.

### AG-E208 VariantWithoutBlockError {#ag-e208}

`ActiveGenie::Eval::VariantWithoutBlockError`

**Raised when** a `variant` in `eval.rb` has no block.

**How to fix:** give it the code to run, as you would `call`: `variant :fast do |input, context| ... end`.

### AG-E209 MissingCallBlockError {#ag-e209}

`ActiveGenie::Eval::MissingCallBlockError`

**Raised when** an eval runs and its `eval.rb` has no `call` block.

**How to fix:** add one that calls your feature and returns what it returns:
`call { |input, context| TicketRouter.new(model: context.model).call(input['text']) }`.

### AG-E210 UnknownGraderError {#ag-e210}

`ActiveGenie::Eval::UnknownGraderError`

**Raised when** `eval.rb` names a grader the engine doesn't have.

**How to fix:** use `:fields`, `:band`, `:list`, `:rubric` or `:winner`, or a block
`{ |output, gold, row| ... }` that returns true, false or a Hash with `"pass"`.

### AG-E211 UnknownCheckError {#ag-e211}

`ActiveGenie::Eval::UnknownCheckError`

**Raised when** a `fields` gold uses a check the engine doesn't have.

**How to fix:** use one of `eq`, `one_of`, `regex`, `contains_any`, `contains_all`, `gte`, `lte`,
`between`, `near`, `nonempty` or `date`. `rake active_genie:eval:check` names every field that uses
another.

### AG-E212 UnknownListCheckError {#ag-e212}

`ActiveGenie::Eval::UnknownListCheckError`

**Raised when** a `list` gold uses a check type the engine doesn't have.

**How to fix:** use one of the types the message lists. `rake active_genie:eval:check` names every row
that uses another.

### AG-E213 UnknownModeError {#ag-e213}

`ActiveGenie::Eval::UnknownModeError`

**Raised when** `MODE=` is not `quick` or `full`.

**How to fix:** use `MODE=quick` (the dev pool, the default) or `MODE=full` (every case).

### AG-E214 MissingGoldError {#ag-e214}

`ActiveGenie::Eval::MissingGoldError`

**Raised when** a case is graded and its row has no gold.

**How to fix:** add a `gold` to the row in `evals/<name>/datasets.jsonl`, or label it with
`active_genie:eval:blind` and `active_genie:eval:label`. `rake active_genie:eval:check` lists every
row without one.

### AG-E215 InvalidJsonlError {#ag-e215}

`ActiveGenie::Eval::InvalidJsonlError`

**Raised when** a line of a `.jsonl` file (a dataset, gold labels, judge verdicts) isn't valid JSON.
The message names the file and line.

**How to fix:** each line is one JSON object. Fix that line (a trailing comma, an unescaped quote or
a line break inside a string is the usual cause), then run `rake active_genie:eval:check`.

### AG-E216 JudgeConfigMissingError {#ag-e216}

`ActiveGenie::Eval::JudgeConfigMissingError`

**Raised when** a case needs the LLM judge and `evals/config.yml` has no `judge:`, or a judge without
`provider` or `model`.

**How to fix:** pin the judge in `evals/config.yml`, and keep it fixed: its verdicts are cached in
`evals/judge/<model>.jsonl`, and a new judge means a new baseline.

```yaml
judge:
  provider: anthropic
  model: claude-sonnet-5-5
```

### AG-E217 MalformedJudgeAnswerError {#ag-e217}

`ActiveGenie::Eval::MalformedJudgeAnswerError`

**Raised when** the LLM judge answers, but not in the shape its question asks for. Nothing is cached,
so the case stays unjudged.

**How to fix:** run the eval again to ask once more. If it keeps happening, pin a judge model that
follows function calling better.

### AG-E218 InvalidLabelPassError {#ag-e218}

`ActiveGenie::Eval::InvalidLabelPassError`

**Raised when** a label in `gold.jsonl` names a pass other than `a` or `b`.

**How to fix:** set `"pass"` to `"a"` (the first blind labeler) or `"b"` (the second).

### AG-E219 CustomGraderLabelingError {#ag-e219}

`ActiveGenie::Eval::CustomGraderLabelingError`

**Raised when** `active_genie:eval:label` runs on an eval whose grader is a block, which has no gold
fields to label.

**How to fix:** set each row's `"status"` in `datasets.jsonl` by hand: `decided` to run it,
`excluded` to skip it.

### AG-E220 InvalidWinnerLabelError {#ag-e220}

`ActiveGenie::Eval::InvalidWinnerLabelError`

**Raised when** a labeling pass of a `winner` eval gives a winner other than `a`, `b` or `either`.

**How to fix:** fix that label's `"winner"` in `gold.jsonl`, in the row's own terms (`a` is
`player_a`, `b` is `player_b`).

### AG-E221 InvalidListLabelError {#ag-e221}

`ActiveGenie::Eval::InvalidListLabelError`

**Raised when** a labeling pass of a `list` eval gives something other than an array of answers.

**How to fix:** write it as a JSON array, for example `"list": ["first answer", "second answer"]`.

### AG-E222 NoRunToBaselineError {#ag-e222}

`ActiveGenie::Eval::NoRunToBaselineError`

**Raised when** `active_genie:eval:save` finds no run for the current code. Runs are keyed by a hash
of the watched files, so a code change needs a new run.

**How to fix:** run `rake active_genie:eval:full EVAL=<name>`, then save.

### AG-E223 IncompleteRunError {#ag-e223}

`ActiveGenie::Eval::IncompleteRunError`

**Raised when** `active_genie:eval:save` finds cases of the run missing or errored.

**How to fix:** run `rake active_genie:eval:full EVAL=<name>` again. It reruns only the missing and
errored cases, and a baseline needs every case.

### AG-E224 UnjudgedRunError {#ag-e224}

`ActiveGenie::Eval::UnjudgedRunError`

**Raised when** `active_genie:eval:save` finds cases still waiting for the LLM judge.

**How to fix:** run the eval again to judge them, or pass `FORCE=1` to save them unjudged.

### AG-E225 DirtyWorktreeError {#ag-e225}

`ActiveGenie::Eval::DirtyWorktreeError`

**Raised when** `active_genie:eval:save` runs while the eval's watched files have uncommitted
changes, so the baseline would not match a commit.

**How to fix:** commit the changes and save again, or pass `FORCE=1` to save anyway.

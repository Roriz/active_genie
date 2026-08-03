# ActiveGenie v0.32.2 Release Notes

Support for the current generation of provider models, plus fixes to the end-to-end suite that had been misreporting `Extractor` quality. Benchmark numbers were re-measured from scratch against `gpt-5.6-luna`, `claude-haiku-4-5`, `gemini-3.5-flash-lite`, and `deepseek-v4-flash`.

## What's Changed

### 1. Fixed: reasoning models could not be used at all

Two of the four current models were unusable with ActiveGenie before this release. Both failed at the request layer, so nothing they did ever reached a module.

`gpt-5.6-luna` returned a 400: *"Function tools with reasoning_effort are not supported for gpt-5.6-luna in /v1/chat/completions. To use function tools, use /v1/responses or set reasoning_effort to 'none'."* ActiveGenie never sends `reasoning_effort`, so the model reasons by default and OpenAI then refuses function tools.

`deepseek-v4-flash` returned a 400: *"Thinking mode does not support this tool_choice."* ActiveGenie forces `tool_choice` to a named function, which thinking-mode models reject.

Both providers now detect the specific error and retry once with an adjusted payload: `reasoning_effort: 'none'` for OpenAI, `tool_choice: 'auto'` for DeepSeek. The detection is based on the error text rather than a list of model names, so a future reasoning model works without a code change.

The fallback only triggers on the matching error. Sending `reasoning_effort` unconditionally would break non-reasoning models, which reject it as an unrecognized argument.

### 2. Anthropic model alias

`recommended_model` and the provider `default_model` now use the `claude-haiku-4-5` alias rather than the pinned `claude-haiku-4-5-20251001` snapshot, so the alias tracks the current release. This also resolves two unit tests that had been asserting the alias and failing. The unit suite is green.

### 3. Fixed: end-to-end tests that could not pass

Nine tests in the suite were failing for reasons unrelated to model quality.

Six called `Extractor.data`, which returns string keys, and then read the result with symbol keys. Every lookup returned `nil`. This is the same string versus symbol inconsistency documented in the Extractor guide, and the test suite was tripping over it too.

Three declared `type: 'array'` without an `items` type. `gpt-5.6-luna` validates schemas strictly and rejected them with a 400; the other three providers accepted them and returned `nil` for the field.

Together these had been holding `Extractor` at roughly 65% on every provider. After the fix it scores 90% to 100%. The module was never the weak point the earlier numbers suggested. Assertions were not loosened, only the key access and schema declarations were corrected.

### 4. Benchmark re-measured

All four providers ran the same 100 tests on the same day against this version.

| Provider | Model | Pass rate |
| :--- | :--- | :---: |
| OpenAI | `gpt-5.6-luna` | 94% |
| Anthropic | `claude-haiku-4-5` | 91% |
| Google | `gemini-3.5-flash-lite` | 91% |
| DeepSeek | `deepseek-v4-flash` | 86% |

Zero errors across all four runs, against 6 in the previous measurement.

The benchmark page now also states plainly how to read the numbers, including which columns are distorted by known defects.

### 5. Known issues affecting the benchmark

`Ranker.by_scoring` returns the internal batching structure rather than the scored players, so a request for three scored items yields one batch. Four `Ranker` tests fail on every provider because of this and cannot pass on any model until it is fixed. It accounts for most of the gap between `Ranker` and the other modules.

`Comparator` scores 100% on three of four providers, so its assertions no longer separate strong models from weak ones and are due for tightening.

`Comparator.by_fight` returned a nil winner twice on `claude-haiku-4-5`, while `by_debate` passed every test on the same model. That points at the fight prompt rather than the model.

### 6. Benchmark model defaults

`test/e2e/test_helper.rb` now targets the four models above. These are deliberately separate from the library's own provider defaults, which are unchanged, so benchmarking a new model does not alter what the gem does for everyone else.

---

## Upgrading

No code changes are required, and no public API changed. Upgrade if you want to use `gpt-5.6-luna` or `deepseek-v4-flash`, which do not work on earlier versions.

```ruby
gem 'active_genie', '0.32.2'
```

```bash
bundle install
```

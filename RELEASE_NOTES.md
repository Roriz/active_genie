# ActiveGenie v0.31.0 Release Notes

This release introduces LLM token logprobs continuous scoring across provider layers and evaluation modules to improve decision accuracy and precision.

## What's Changed

### Features & Continuous Scoring Architecture

1. **Logprobs Continuous Scoring Engine (`ActiveGenie::Utils::LogprobsCalculator`)**:
   - Computes continuous expected rewards $R(x, \tau) = \sum \phi(v_g) \cdot p_\theta(v_g)$ from token log probabilities.
   - Converts token log probabilities $p = e^{\text{logprob}}$ across numeric scale tokens and letter-mapped tokens (`A`..`E`).
   - Linearly normalizes continuous expected values into $[0.0, 1.0]$ ranges and aggregates multi-pass scores across criteria and repetitions.

2. **Provider Logprobs Support**:
   - **Google Provider (`GoogleProvider`)**: Enabled `responseLogprobs` and `logprobs` in `generationConfig`. Added automatic fallback for models where logprobs are unsupported by the API endpoint.
   - **OpenAI Provider (`OpenaiProvider`)**: Added `logprobs` and `top_logprobs` parameters in Chat Completions. Standardized OpenAI step logprobs into unified `chosenCandidates` and `topCandidates` structure.

3. **Debate Comparator Logprobs Decision (`Comparator::Debate`)**:
   - Computes continuous expected reward scores $R_A$ and $R_B$ across adherence, quality, and risk-avoidance sub-criteria.
   - Determines winners using continuous expected reward scores and candidate probability metrics.

4. **JuryBench Scorer Continuous Scoring (`Scorer::JuryBench`)**:
   - Extracts candidate logprobs for `final_score` and individual juror scores.
   - Returns continuous floating-point scores in `result.data` and rich logprobs metadata in `result.metadata`.

5. **Updated Default Provider Models**:
   - Google default model updated to `gemini-3.5-flash-lite`.
   - OpenAI default model updated to `gpt-5.6-luna`.

---

## Installation

To upgrade to the latest version of `active_genie`, update your Gemfile:

```ruby
gem 'active_genie', '0.31.0'
```

And run:

```bash
bundle install
```

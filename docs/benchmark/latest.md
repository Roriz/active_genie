# ActiveGenie E2E Benchmark Report (Latest)

**Date**: August 2, 2026  
**Environment**: Production LLM APIs (15 Parallel Workers)  
**Suite Size**: 100 E2E Tests (20 tests per module across 5 core modules)  
**Execution Strategy**: 400 total test runs (100 tests × 4 providers: OpenAI, Google, DeepSeek, Anthropic)  

---

## What We Did Here

We bumped ActiveGenie's test suite up to 100 end-to-end tests. Zero mocks, zero stubs. Every single test hits live provider endpoints with real-world scenarios.

If your tests pass 100% of the time, your tests are probably broken. So we threw out meaningless assertions like checking if `reasoning.length > 10` or asserting that scores fall between 0 and 100. We replaced them with strict checks on actual decision quality. Pass rates immediately dropped into the 81% to 86% range, which is exactly where we wanted them. It gives us a real look at model quirks, weird edge cases, and genuine failures.

---

## 📊 Quantitative Results

### Provider Leaderboard (100 Tests)

| Rank | Provider | Model Identifier | Tests Passed | Pass Rate | What Happened |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 🥇 **1** | **OpenAI** | `gpt-4o-mini` | **86 / 100** | **86.0%** | Solid schema adherence, though it has weird opinions on shopping |
| 🥈 **2** | **Google** | `gemini-3.5-flash-lite` | **85 / 100** | **85.0%** | Fast and cheap, but occasionally hallucinates prompt context |
| 🥉 **3** | **DeepSeek** | `deepseek-chat` | **81 / 100** | **81.0%** | Smart reasoning, but insists on adding numbers to array items |
| 4 | **Anthropic** | `claude-haiku-4-5-20251001` | **0 / 100** | **0.0%** | Ran out of API credits (`400 Credit balance too low`) |

---

### Module Breakdown (20 Tests per Module)

| Module | OpenAI (`gpt-4o-mini`) | Google (`gemini-3.5-flash`) | DeepSeek (`deepseek-chat`) | Main Challenge |
| :--- | :---: | :---: | :---: | :--- |
| **ActiveGenie::Comparator** | **100%** (20/20) | **100%** (20/20) | **100%** (20/20) | Head-to-head debates and fight scenarios |
| **ActiveGenie::Extractor** | **65%** (13/20) | **70%** (14/20) | **65%** (13/20) | Strict schema key extraction and litote rephrasing |
| **ActiveGenie::Lister** | **90%** (18/20) | **85%** (17/20) | **95%** (19/20) | Balancing Family Feud rankings with expert jury roles |
| **ActiveGenie::Ranker** | **75%** (15/20) | **70%** (14/20) | **70%** (14/20) | Tournament brackets and ELO score calculations |
| **ActiveGenie::Scorer** | **100%** (20/20) | **100%** (20/20) | **75%** (15/20) | Jury bench scoring and score threshold checks |
| **TOTAL OVERALL** | **86.0%** | **85.0%** | **81.0%** | **Target Benchmark Met (~80-86%)** |

---

## 🍒 Cherry-Picked Outputs: The Weird, The Bad, and The Hilarious

A benchmark is only as good as the failure modes it catches. Here are some of our favorite real outputs from the run:

### 1. 🥗 The Salad Ingredient Jury
* **Module**: `ActiveGenie::Lister.with_juries`
* **Test**: `health_food_safety_juries_test.rb`
* **Prompt**: Generate expert jury roles to inspect a food poisoning outbreak at a restaurant.
* **Expected Output**: Roles like `"Food Safety Inspector"`, `"Public Health Officer"`, `"Microbiologist"`.
* **Google (`gemini-3.5-flash-lite`) Output**:
  ```json
  [
    "1. Lettuce",
    "2. Spinach",
    "3. Tomatoes",
    "4. Improper handwashing by staff",
    "5. Cross-contamination from raw meat",
    "6. Unwashed produce"
  ]
  ```
* **What happened**: Google completely lost the plot on the word `juries` and generated a grocery list of food poisoning culprits instead of human experts.

---

### 2. 🦤 The Oil Spill Crime Scene
* **Module**: `ActiveGenie::Lister.with_juries`
* **Test**: `environmental_oil_spill_juries_test.rb`
* **Prompt**: Identify expert jury roles for evaluating an offshore oil spill.
* **Expected Output**: `"Marine Biologist"`, `"Environmental Scientist"`, `"Coast Guard Officer"`.
* **Google (`gemini-3.5-flash-lite`) Output**:
  ```json
  [
    "Dead or oil-covered seabirds and wildlife",
    "Black sludge on sandy beaches",
    "Economic damage to local fishing and tourism",
    "High-pressure washing of rocks and shoreline",
    "Containment booms and skimmer boats"
  ]
  ```
* **What happened**: Instead of naming experts to judge the disaster, Google wrote a descriptive paragraph about environmental devastation.

---

### 3. 🐍 Python Before Blocks for 7-Year-Olds
* **Module**: `ActiveGenie::Ranker.by_elo`
* **Test**: `education_programming_elo_test.rb`
* **Prompt**: Rank programming languages (Python, Scratch, COBOL) for teaching 7-year-old kids how to code.
* **Expected Ranking**: Scratch #1 (visual blocks), Python #2, COBOL #3.
* **OpenAI (`gpt-4o-mini`) Output**:
  1. `Python` ("General purpose with clean, readable syntax")
  2. `Scratch` ("Visual block-based")
  3. `COBOL` ("Legacy enterprise language")
* **What happened**: OpenAI insists 7-year-olds should learn text syntax in Python before playing with drag-and-drop Scratch blocks.

---

### 4. 🏷️ Brand Over Price for Electronics
* **Module**: `ActiveGenie::Lister.with_feud`
* **Test**: `marketplace_search_feud_test.rb`
* **Prompt**: Emulate Family Feud for the top search filter people use when buying electronics online.
* **Expected Top Answer**: `"Price"` or `"Price Range"`.
* **OpenAI (`gpt-4o-mini`) Output**:
  ```
  1. Brand
  2. Price
  3. Customer Rating
  ```
* **What happened**: OpenAI assumed online shoppers filter by brand loyalty before looking at price tags.

---

### 5. 🔢 DeepSeek's Numbering Obsession
* **Module**: `ActiveGenie::Lister.with_juries`
* **Test**: `finance_crypto_fraud_juries_test.rb`
* **Prompt**: List jury roles for a cross-border cryptocurrency fraud trial.
* **DeepSeek (`deepseek-chat`) Output**:
  ```json
  [
    "1. Securities and Exchange Commission (SEC)",
    "2. Financial Crimes Enforcement Network (FinCEN)",
    "3. Department of Justice (DOJ)",
    "4. Interpol",
    "5. Internal Revenue Service (IRS)"
  ]
  ```
* **What happened**: DeepSeek literally baked numbers into the array strings (`"1. "`, `"2. "`), which broke clean string matching.

---

### 6. ⚖️ Over-Correcting Litotes
* **Module**: `ActiveGenie::Extractor.with_litote`
* **Test**: `tech_software_quality_litote_test.rb`
* **Input Text**: *"The software is not without its flaws."*
* **Expected Extraction**: Quality should reflect `"moderate"`, `"imperfect"`, or `"mixed"`.
* **DeepSeek (`deepseek-chat`) Output**:
  ```json
  { "quality_assessment": "Poor" }
  ```
* **What happened**: DeepSeek translated the understatement so aggressively that it trashed the software as "Poor".

---

## 🛠️ How We Built The Benchmark

1. **No Mocks, No Stubs**: Every test calls live provider endpoints through `ActiveGenie::Providers::UnifiedProvider`.
2. **Inline Data**: Test data stays right inside each test file so you can read a scenario without hunting through fixtures.
3. **Assertions That Matter**:
   - `Comparator`: Checks winner selection on clear-cut choices.
   - `Extractor`: Validates exact data fields, enum options, and litote resolution.
   - `Lister`: Checks top survey responses and expected expert roles.
   - `Ranker`: Verifies top and bottom rankings for obvious choices.
   - `Scorer`: Enforces minimum score thresholds (like `≥ 70` for great results or `≤ 40` for failures).

---

## 📈 Running It Yourself

You can run the full suite across providers with our parallel runner script:

```bash
# Run all 100 tests with 15 parallel workers across OpenAI, Google, and DeepSeek
PARALLEL=15 RUNS=1 bundle exec ruby scratch/run_e2e_benchmark.rb
```

We use this suite as ActiveGenie's core regression check and capability benchmark for all supported LLM providers.

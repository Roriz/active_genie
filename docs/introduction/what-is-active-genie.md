# What is ActiveGenie?
ActiveGenie is a developer-first library for GenAI workflows, designed to help you compare, rank, and score LLM outputs with consistency and model-agnostic flexibility. Think of it as the Lodash for GenAI: built for real value, consistent results, and freedom from vendor lock-in. It solves the biggest pain in GenAI today: getting predictable, trustworthy answers across use cases, models, and providers.

> [!TIP]
> Just want to try it out? Skip to the [Quickstart](/introduction/quick-start).

## Real Value

### Product Comparison by a Relative Metric
Given two different dresses,

| Image | Dress | Description |
|-------|-------------|-------|
| ![Cozy Cielo Home Dress](/assets/cozy-cielo-home-dress.webp) | Cozy Cielo Home Dress | Made from a soft cotton blend, it features a relaxed fit, scoop neckline, and convenient side pockets. |
| ![Glamour Noir Dress](/assets/glamour-noir-dress.webp) | Glamour Noir Dress | Crafted from a luxurious, shimmering fabric, this dress features a sleek, form-fitting silhouette and an elegant V-neckline. |

what is the best dress for a Friday night? The `ActiveGenie::Battle` will answer: `Glamour Noir Dress`.
See the test case: [dresses_test.rb](https://github.com/Roriz/active_genie/blob/main/benchmark/test_cases/battle/generalist_test.rb#L30)


### Prioritization by Other Field Knowledge
Given a Jira ticket, what is the complexity of the task?
- Task description: Develop an AI-powered dynamic pricing engine that automatically adjusts product prices in real-time based on market trends...

The `ActiveGenie::Scoring` will answer with a score greater than 80.

See the test case: [great_scores_test.rb](https://github.com/Roriz/active_genie/blob/main/benchmark/test_cases/scoring/great_scores_test.rb#L60)

### Ranking by Uncertainty
Given a list of Marvel characters, who is the strongest without any restrictions?
- A list of 51 Marvel characters, with descriptions and achievements in the MCU.
![MCU Characters](/assets/mcu-characters.webp)

The `ActiveGenie::Ranking` will answer:
- Thanos in the top 3
- Tony Stark in the top 20
- Happy Hogan in the bottom 5

See the test case: [mcu_test.rb](https://github.com/Roriz/active_genie/blob/main/benchmark/test_cases/ranking/mcu_test.rb#L8)


## Consistent

A benchmarking system to ensure consistent, high-quality outputs across different LLM models and providers.

| Model | Overall Precision |
|-------|-------------------|
| claude-3-5-haiku-20241022 | 92.25% |
| gemini-2.0-flash-lite | 84.25% |
| gpt-4o-mini | 62.75% |
| deepseek-chat | 57.25% |

With every new release of ActiveGenie, we run our benchmarking system to ensure that the modules continue to function as expected. This benchmark includes tons of simulated use cases that can help you discover what fits best for your needs. Ideally, we would test every possible use case, but we haven't reached that goal yet. To increase the number of use cases, we create case studies from issues and messages we receive from users. If you have an interesting use case, please open an issue, and we will add it as soon as possible.

See [more](benchmark/latest) for detailed results, our methodology, and how you can contribute to our test suite.

## Model-Agnostic

All modules are model-agnostic, meaning they can work with all supported LLM models and providers. This ensures that the modules can continue to function even if the model or provider changes. Of course, each model has its own strengths and weaknesses. We recommend using the model that best suits your needs, and we can help you choose the best one for your use case based on our benchmarking results.

Each provider publishes its own best practices and tricks in documents like Google's [Prompt Engineering Guide](https://www.kaggle.com/whitepaper-prompt-engineering) or OpenAI's [Text Generation Guide](https://platform.openai.com/docs/guides/text). But it's hard to apply all these rules at once. They often work best in specific use cases and, even worse, they change over time. As if following these official documents wasn't hard enough, there are tons of unofficial techniques that may or may not work for your use case, like being more aggressive or promising a reward. With ActiveGenie modules, you don’t need to worry about these details. We handle it for you. It’s hard to keep track of everything, but our custom benchmarking helps us improve our prompts.

![Prompt Engineering Chaos](/assets/chaos-ai.webp)

The number of providers and models is growing every day, and we are committed to supporting the most important ones. If you need a specific model or provider, please open an issue, and we will add it as soon as possible.

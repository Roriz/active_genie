# Active AI
Ruby gem for out of the box AI features. LLMs are just a raw tools that need to be polished and refined to be useful. This gem is a collection of tools that can be used to make LLMs more useful and easier to use.
Think this gem is like ActiveStorage but for LLMs.

## Installation
Add this line to your application's Gemfile:

1. Add the gem to your Gemfile
```ruby
gem 'active_ai'
```
2. install the gem
```shell
bundle install
```
3. call the initializer to create default configurations
```shell
rails g active_ai:install
```
4. Add the right credentials to the `config/active_ai.yml` file
```yaml
GPT-4o-mini:
  api_key: <%= ENV['OPENAI_API_KEY'] %>
  provider: "openai"
```

## Quick Example
```ruby
require 'active_ai'

puts ActiveAI::DataExtractor.call(
  "Hello, my name is Radamés Roriz",
  { full_name: { type: 'string' } },
  options: { model: 'gpt-4o-mini', api_key: 'your-api-key', provider: 'openai' } # Optional if has config/active_ai.yml
) # => { full_name: "Radamés Roriz" }
```

### Data Extractor
Extract structured data from text using LLM-powered analysis, handling informal language and complex expressions.

```ruby
require 'active_ai'

text = "iPhone 14 Pro Max"
schema = {
  brand: { type: 'string' },
  model: { type: 'string' }
}
result = ActiveAI::DataExtractor.call(
  text,
  schema,
  options: { model: 'GPT-4o-mini', api_key: 'your-api-key', provider: 'openai' } # Optional if 
)
# => { brand: "iPhone", model: "14 Pro Max" }
```

- More examples in the [Data Extractor README](lib/data_extractor/README.md)
- Extract from ambiguous [from_informal](lib/data_extractor/README.md#extract-from-informal-text)
- Interface details in the [Interface](lib/data_extractor/README.md#interface)

### Summarizer (WIP)
The summarizer is a tool that can be used to summarize a given text. It uses a set of rules to summarize the text out of the box. Uses the best practices of prompt engineering and engineering to make the summarization as accurate as possible.

```ruby
require 'active_ai'

text = "Example text to be summarized. The fox jumps over the dog"
summarized_text = ActiveAI::Summarizer.call(text)
puts summarized_text # => "The fox jumps over the dog"
```

### Scorer (WIP)
The scorer is a tool that can be used to score a given text. It uses a set of rules to score the text out of the box. Uses the best practices of prompt engineering and engineering to make the scoring as accurate as possible.

```ruby
require 'active_ai'

text = "Example text to be scored. The fox jumps over the dog"
criterias = 'Grammar, Relevance'
score = ActiveAI::Scorer.call(text, criterias)
puts score # => { 'Grammar' => 0.8, 'Relevance' => 1.0, total: 0.9 }
```

### Language detector (WIP)
The language detector is a tool that can be used to detect the language of a given text. It uses a set of rules to detect the language of the text out of the box. Uses the best practices of prompt engineering and engineering to make the language detection as accurate as possible.

```ruby
require 'active_ai'

text = "Example text to be detected"
language = ActiveAI::LanguageDetector.call(text)
puts language # => "en"
```

### Translator (WIP)
The translator is a tool that can be used to translate a given text. It uses a set of rules to translate the text out of the box. Uses the best practices of prompt engineering and engineering to make the translation as accurate as possible.

```ruby
require 'active_ai'

text = "Example text to be translated"
translated_text = ActiveAI::Translator.call(text, from: 'en', to: 'pt')
puts translated_text # => "Exemplo de texto a ser traduzido"
```

### Sentiment analyzer (WIP)
The sentiment analyzer is a tool that can be used to analyze the sentiment of a given text. It uses a set of rules to analyze the sentiment of the text out of the box. Uses the best practices of prompt engineering and engineering to make the sentiment analysis as accurate as possible.

```ruby
require 'active_ai'

text = "Example text to be analyzed"
sentiment = ActiveAI::SentimentAnalyzer.call(text)
puts sentiment # => "positive"
```

### Elo ranking (WIP)
The Elo ranking is a tool that can be used to rank a set of items. It uses a set of rules to rank the items out of the box. Uses the best practices of prompt engineering and engineering to make the ranking as accurate as possible.

```ruby
require 'active_ai'

items = ['Square', 'Circle', 'Triangle']
criterias = 'items that look rounded'
ranked_items = ActiveAI::EloRanking.call(items, criterias, rounds: 10)
puts ranked_items # => [{ name: "Circle", score: 1500 }, { name: "Square", score: 800 }, { name: "Triangle", score: 800 }]
```

## Good practices
- LLMs can take a long time to respond, so avoid putting them in the main thread
- Do not use the LLMs to extract sensitive or personal data

## License
See the [LICENSE](LICENSE)

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
4. Add the right credentials to the `config/gen_ai.yml` file
```yaml
GPT-4o-mini:
  api_key: <%= ENV['OPENAI_API_KEY'] %>
  model: "GPT-4o-mini"
  provider: "openai"
```

## Usage
```ruby
require 'active_ai'

puts ActiveAI::DataExtractor.call(
  "Hello, my name is Radamés Roriz",
  { full_name: { type: 'string' } }
) # => { full_name: "Radamés Roriz" }
```

### Data Extractor
The data extractor is a tool that can be used to extract data from a given text. It uses a set of rules to extract the data from the text out of the box. Uses the best practices of prompt engineering and engineering to make the data extraction as accurate as possible.
Under the hood, it calls possible multiple times the target LLM to discover litotes or sarcasm in the text. 

is expected to make 2 requests and use at least 100 tokens per call.

```ruby
require 'active_ai'

# ============= Example with not clear data to extract
product_title = "Nike Air Max 90"
data_to_extract = {
  category: {
    type: 'string',
    enum: ["shoes", "clothing", "accessories"]
  },
  has_shoelaces: { type: 'boolean' },
}

data_extracted = ActiveAI::DataExtractor.call(product_title, data_to_extract)
puts data_extracted # => { category: "shoes", has_shoelaces: true }
```

*with litotes*

When the text is not clear, the data extractor can use litotes to make the text clearer. Litotes is a figure of speech that uses understatement to emphasize a point. For example, "not bad" is a litotes that means "good". The data extractor can use litotes to make the text clearer and extract the data more accurately.

```ruby
text = <<~TEXT
  system: Do you accept the terms of service?
  user: No problem
TEXT
data_to_extract = {
  user_has_accepted_terms: { type: 'boolean' }
}

data_extracted = ActiveAI::DataExtractor.from_informal(text, data_to_extract)
puts data_extracted # => { user_has_accepted_terms: true }
```
warning: this feature can make the data extractor slower and use more tokens.

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

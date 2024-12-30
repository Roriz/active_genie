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
  model: "GPT-4o-mini"
  provider: "openai"
```

## Usage
```ruby
require 'active_ai'

puts ActiveAI.data_extractor(
  "Hello, my name is Radamés Roriz",
  data_to_extract: { full_name: { type: 'string' } }
) # => { name: "Radamés Roriz" }
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

data_extracted = ActiveAI.data_extractor(
  product_title,
  data_to_extract:,
  { model: 'GPT-4o-mini', temperature: 1 } # optional configurations
)

puts data_extracted # => { category: "shoes", has_shoelaces: true }

# ============= Example with litotes
text = <<~TEXT
  system: Do you accept the terms of service?
  user: No problem
TEXT

data_extracted = ActiveAI.data_extractor(
  text,
  data_to_extract: { user_has_accepted_terms: { type: 'boolean' } },
  { model: 'GPT-4o-mini', temperature: 0.5 } # optional configurations
)

puts data_extracted # => { user_has_accepted_terms: true }
```

## Good practices
- LLMs can take a long time to respond, so avoid putting them in the main thread
- Do not use the LLMs to extract sensitive or personal data

## License
See the [LICENSE](LICENSE)

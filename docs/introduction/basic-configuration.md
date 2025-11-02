# Basic Configuration

| Config | Type | Description | Default |
|--------|------|-------------|---------|
| `llm.model` | String | Model to use | `nil` |
| `llm.temperature` | Float | Temperature to use | `0` |
| `llm.max_tokens` | Integer | Maximum tokens to use | `4096` |
| `llm.max_retries` | Integer | Maximum retry attempts | `3` |
| `log.output` | Proc | Log output | `->(log) { $stdout.puts log }` |
| `ranking.score_variation_threshold` | Integer | Score variation threshold | `30` |

> **Note:** Each module can append its own set of configuration, see the individual module documentation for details.

Read all [configuration](/reference/config) for all available options.

## How to create a new provider

ActiveGenie supports adding custom providers to integrate with different LLM services. To create a new provider:

1. Create a configuration class for your provider in `lib/active_genie/configuration/providers/`:
2. Register your client

```ruby
class InternalCompanyApi
  # @param messages [Array<Hash>] A list of messages representing the conversation history.
  #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
  # @param function [Hash] A JSON schema definition describing the desired output format.
  # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
  def function_calling(messages, function)
    # ...
  end
end

ActiveGenie.configure do |config|
  config.llm.client = InternalCompanyApi
end
# or
ActiveGenie::Comparator.call('player_a', 'player_b', 'criteria', { client: InternalCompanyApi })
```

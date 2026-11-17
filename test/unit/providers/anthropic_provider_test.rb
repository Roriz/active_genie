# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/anthropic_provider'

module ActiveGenie
  module Providers
    class AnthropicProviderTest < Minitest::Test
      URL = 'https://api.anthropic.com/v1/messages'
      FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: { type: 'object', properties: { score: { type: 'integer' } } }
      }.freeze

      def setup
        config = Configuration.new({
                                     llm: { model: 'claude-haiku-4-5' },
                                     providers: { anthropic: { api_key: 'test_key' } }
                                   })
        @provider = AnthropicProvider.new(config)
        stub_request(:post, URL).to_return(body: {
          content: [{ type: 'tool_use', name: 'score_function', input: { score: 8 } }],
          usage: { input_tokens: 10, output_tokens: 5 }
        }.to_json)
      end

      def test_joins_every_system_message_into_the_system_prompt
        messages = [
          { role: 'system', content: 'You are a judge.' },
          { role: 'system', content: 'List 7 top items.' },
          { role: 'user', content: 'Score this essay' }
        ]

        @provider.function_calling(messages, FUNCTION)

        assert_requested(:post, URL) do |req|
          body = JSON.parse(req.body)
          body['system'] == "You are a judge.\n\nList 7 top items." &&
            body['messages'] == [{ 'role' => 'user', 'content' => 'Score this essay' }]
        end
      end

      def test_sends_an_empty_system_prompt_when_there_is_no_system_message
        result = @provider.function_calling([{ role: 'user', content: 'Score this essay' }], FUNCTION)

        assert_equal({ 'score' => 8 }, result)
        assert_requested(:post, URL) { |req| JSON.parse(req.body)['system'] == '' }
      end
    end
  end
end

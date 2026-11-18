# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/deepseek_provider'

module ActiveGenie
  module Providers
    class DeepseekProviderTest < Minitest::Test
      URL = 'https://api.deepseek.com/v1/chat/completions'
      FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: { type: 'object', properties: { score: { type: 'integer' } } }
      }.freeze
      MESSAGES = [{ role: 'user', content: 'Score this essay' }].freeze

      def setup
        @dir = Dir.mktmpdir
      end

      def teardown
        super # webmock/minitest resets its request registry here
        FileUtils.remove_entry(@dir)
      end

      def test_repairs_unquoted_string_values_in_tool_arguments
        stub_arguments('{"label": positive}')

        assert_equal({ 'label' => 'positive' }, provider.function_calling(MESSAGES, FUNCTION))
      end

      def test_raises_invalid_response_error_when_arguments_cannot_be_repaired
        stub_arguments('{"score": [8,')

        error = assert_raises(DeepseekProvider::InvalidResponseError) { provider.function_calling(MESSAGES, FUNCTION) }

        assert_includes error.message, '{"score": [8,'
      end

      def test_schema_field_named_message_is_returned_intact
        function = { name: 'extract', parameters: { type: 'object', properties: { message: { type: 'string' } } } }
        stub_arguments('{"message": "Order arrived late"}')

        assert_equal({ 'message' => 'Order arrived late' }, provider.function_calling(MESSAGES, function))
      end

      private

      def stub_arguments(arguments)
        body = { choices: [{ message: { tool_calls: [{ function: { arguments: } }] } }],
                 usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }
        stub_request(:post, URL).to_return(body: body.to_json)
      end

      def provider
        DeepseekProvider.new(
          Configuration.new(
            llm: { model: 'deepseek-flash' },
            providers: { deepseek: { api_key: 'test_key' } },
            log: {
              output: ->(_log) {},
              file_path: File.join(@dir, 'active_genie.log'),
              fine_tune_file_path: File.join(@dir, 'fine_tune.log')
            }
          )
        )
      end
    end
  end
end

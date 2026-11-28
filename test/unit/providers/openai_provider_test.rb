# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/openai_provider'

module ActiveGenie
  module Providers
    class OpenaiProviderTest < Minitest::Test
      EXAMPLE_FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: {
          type: 'object',
          properties: {
            score: { type: 'integer' }
          }
        }
      }.freeze
      EXAMPLE_MESSAGES = [{ role: 'user', content: 'Score this essay' }].freeze

      def setup
        @config = Configuration.new({
                                      llm: { model: 'gpt-5.6-luna' },
                                      providers: { openai: { api_key: 'test_key' } }
                                    })
        @provider = OpenaiProvider.new(@config)
      end

      def test_function_calling_returns_the_parsed_arguments
        mock_response = {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'function' => {
                      'arguments' => '{"score": 8}'
                    }
                  }
                ]
              }
            }
          ]
        }

        @provider.stub(:request, mock_response) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION)

          assert_equal({ 'score' => 8 }, result)
        end
      end

      def test_request_sends_only_the_chat_completion_fields
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'stop')

        call_openai

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          body = JSON.parse(req.body)

          assert_equal %w[messages tools tool_choice stream model temperature], body.keys
          assert_equal 'gpt-5.6-luna', body['model']
          assert_equal({ 'type' => 'function', 'function' => { 'name' => 'score_function' } }, body['tool_choice'])
        end
      end

      # Critical Path: answers without a usable tool call must raise, not
      # return {} as if the model had extracted nothing.
      def test_answer_without_a_tool_call_raises_invalid_response
        stub_openai(message: { content: nil }, finish_reason: 'stop')

        error = assert_raises(ActiveGenie::InvalidResponseError) { call_openai }

        assert_includes error.message, 'no tool call'
      end

      def test_tool_arguments_that_are_not_json_raise_invalid_response
        stub_openai(message: { tool_calls: [tool_call('{"score": ')] }, finish_reason: 'stop')

        assert_raises(ActiveGenie::InvalidResponseError) { call_openai }
      end

      def test_answer_cut_off_by_the_token_limit_raises_truncated_response
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'length')

        error = assert_raises(ActiveGenie::TruncatedResponseError) { call_openai }

        assert_includes error.message, 'length'
      end

      def test_model_refusal_raises_a_refusal_error
        stub_openai(message: { content: nil, refusal: 'I cannot help with that.' }, finish_reason: 'stop')

        error = assert_raises(ActiveGenie::RefusalError) { call_openai }

        assert_includes error.message, 'I cannot help with that.'
      end

      def test_content_filter_raises_a_refusal_error
        stub_openai(message: { content: nil }, finish_reason: 'content_filter')

        assert_raises(ActiveGenie::RefusalError) { call_openai }
      end

      # A schema field named `message` must come back as a field, not be unwrapped.
      def test_schema_field_named_message_is_returned_intact
        function = { name: 'extract', parameters: { type: 'object', properties: { message: { type: 'string' } } } }
        stub_openai(message: { tool_calls: [tool_call('{"message": "Order arrived late"}')] }, finish_reason: 'stop')

        assert_equal({ 'message' => 'Order arrived late' }, @provider.function_calling(EXAMPLE_MESSAGES, function))
      end

      def test_arguments_wrapped_in_message_are_still_unwrapped
        stub_openai(message: { tool_calls: [tool_call('{"message": {"score": 8}}')] }, finish_reason: 'stop')

        assert_equal({ 'score' => 8 }, call_openai)
      end

      private

      def stub_openai(choice)
        body = { choices: [choice], usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }
        stub_request(:post, 'https://api.openai.com/v1/chat/completions').to_return(body: body.to_json)
      end

      def tool_call(arguments)
        { function: { name: 'score_function', arguments: } }
      end

      def call_openai
        @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION)
      end
    end
  end
end

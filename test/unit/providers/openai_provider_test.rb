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

      def test_function_calling_without_logprobs
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

      def test_function_calling_with_logprobs
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
              },
              'logprobs' => {
                'content' => [
                  { 'token' => 'score', 'logprob' => -0.1, 'top_logprobs' => [{ 'token' => 'score', 'logprob' => -0.1 }] },
                  {
                    'token' => '8',
                    'logprob' => -0.22314,
                    'top_logprobs' => [
                      { 'token' => '8', 'logprob' => -0.22314 },
                      { 'token' => '7', 'logprob' => -1.60943 }
                    ]
                  }
                ]
              }
            }
          ]
        }

        captured_payload = nil
        @provider.stub(:request, lambda { |payload|
          captured_payload = payload
          mock_response
        }) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true, top_logprobs: 10)

          assert_equal true, captured_payload[:logprobs]
          assert_equal 10, captured_payload[:top_logprobs]
          assert_equal({ 'score' => 8 }, result[:data])
          refute_nil result[:logprobs]

          candidates = @provider.extract_field_logprobs(result[:logprobs], 'score')

          refute_nil candidates

          score_res = @provider.calculate_continuous_score(candidates, min_score: 1.0, max_score: 10.0)

          refute_nil score_res
          assert_in_delta 7.8, score_res.expected_value, 0.1
        end
      end

      def test_request_without_logprobs_does_not_ask_for_them
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'stop')

        call_openai

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          body = JSON.parse(req.body)

          refute body.key?('logprobs')
          refute body.key?('top_logprobs')
          assert_equal 'gpt-5.6-luna', body['model']
          assert_equal({ 'type' => 'function', 'function' => { 'name' => 'score_function' } }, body['tool_choice'])
        end
      end

      def test_logprobs_requested_but_not_returned_come_back_nil
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'stop')

        result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true)

        assert_equal({ data: { 'score' => 8 }, logprobs: nil }, result)
      end

      def test_logprobs_are_reshaped_into_chosen_and_top_candidates
        stub_openai(
          message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'stop',
          logprobs: { content: [{ token: '8', logprob: -0.2, top_logprobs: [{ token: '8', logprob: -0.2 }] },
                                { token: '}' }] }
        )

        result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true)

        assert_equal(
          {
            'chosenCandidates' => [{ 'token' => '8', 'logProbability' => -0.2 }, { 'token' => '}', 'logProbability' => 0.0 }],
            'topCandidates' => [{ 'candidates' => [{ 'token' => '8', 'logProbability' => -0.2 }] }, { 'candidates' => [] }]
          },
          result[:logprobs]
        )
      end

      def test_empty_logprobs_content_comes_back_nil
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'stop', logprobs: { content: [] })

        assert_nil @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true)[:logprobs]
      end

      # Critical Path: answers without a usable tool call must raise, not
      # return {} as if the model had extracted nothing.
      def test_answer_without_a_tool_call_raises_invalid_response
        stub_openai(message: { content: nil }, finish_reason: 'stop')

        error = assert_raises(BaseProvider::InvalidResponseError) { call_openai }

        assert_includes error.message, 'no tool call'
      end

      def test_tool_arguments_that_are_not_json_raise_invalid_response
        stub_openai(message: { tool_calls: [tool_call('{"score": ')] }, finish_reason: 'stop')

        assert_raises(BaseProvider::InvalidResponseError) { call_openai }
      end

      def test_answer_cut_off_by_the_token_limit_raises_invalid_response
        stub_openai(message: { tool_calls: [tool_call('{"score": 8}')] }, finish_reason: 'length')

        error = assert_raises(BaseProvider::InvalidResponseError) { call_openai }

        assert_includes error.message, 'length'
      end

      def test_model_refusal_raises_a_refusal_error
        stub_openai(message: { content: nil, refusal: 'I cannot help with that.' }, finish_reason: 'stop')

        error = assert_raises(BaseProvider::RefusalError) { call_openai }

        assert_includes error.message, 'I cannot help with that.'
      end

      def test_content_filter_raises_a_refusal_error
        stub_openai(message: { content: nil }, finish_reason: 'content_filter')

        assert_raises(BaseProvider::RefusalError) { call_openai }
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

# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/google_provider'

module ActiveGenie
  module Providers
    class GoogleProviderTest < Minitest::Test
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
                                      llm: { model: 'gemini-3.8-flash' },
                                      providers: { google: { api_key: 'test_key' } }
                                    })
        @provider = GoogleProvider.new(@config)
      end

      def test_function_calling_without_logprobs
        mock_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [{ 'text' => '{"score": 8}' }]
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
        mock_logprobs = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '8' }],
          'topCandidates' => [
            { 'candidates' => [{ 'token' => 'score' }] },
            { 'candidates' => [{ 'token' => '8', 'logProbability' => -0.2 }] }
          ]
        }
        mock_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [{ 'text' => '{"score": 8}' }]
              },
              'logprobsResult' => mock_logprobs
            }
          ]
        }

        captured_payload = nil
        @provider.stub(:request, lambda { |payload|
          captured_payload = payload
          mock_response
        }) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true, top_logprobs: 10)

          assert_equal true, captured_payload[:generationConfig][:responseLogprobs]
          assert_equal 10, captured_payload[:generationConfig][:logprobs]
          assert_equal({ 'score' => 8 }, result[:data])
          assert_equal mock_logprobs, result[:logprobs]
        end
      end

      def test_api_key_is_sent_as_header_and_never_logged
        secret = 'SECRET-GOOGLE-KEY-123'
        logs = []
        Dir.mktmpdir do |dir|
          config = Configuration.new({
                                       llm: { model: 'gemini-2.5-flash' },
                                       providers: { google: { api_key: secret } },
                                       log: {
                                         output: ->(log) { logs << log },
                                         file_path: File.join(dir, 'active_genie.log'),
                                         fine_tune_file_path: File.join(dir, 'fine_tune.log')
                                       }
                                     })
          stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash:generateContent})
            .to_return(body: {
              candidates: [{ content: { parts: [{ text: '{"score": 8}' }] } }],
              usageMetadata: { promptTokenCount: 1, candidatesTokenCount: 1, totalTokenCount: 2 }
            }.to_json)

          GoogleProvider.new(config).function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION)

          assert_requested(:post, /generateContent/) do |req|
            req.uri.query.nil? && req.headers['X-Goog-Api-Key'] == secret
          end
          refute_empty logs
          logs.each { |log| refute_includes log.to_s, secret }
          Dir.glob(File.join(dir, '*.log')).each { |file| refute_includes File.read(file), secret }
        end
      end

      # Critical Path: answers without usable text must raise a clear error,
      # not return nil for every module to crash on.
      def test_blocked_prompt_raises_a_refusal_error
        stub_google(promptFeedback: { blockReason: 'SAFETY' })

        error = assert_raises(BaseProvider::RefusalError) { call_google }

        assert_includes error.message, 'SAFETY'
      end

      def test_blocked_candidate_raises_a_refusal_error
        stub_google(candidates: [{ finishReason: 'PROHIBITED_CONTENT' }])

        error = assert_raises(BaseProvider::RefusalError) { call_google }

        assert_includes error.message, 'PROHIBITED_CONTENT'
      end

      def test_answer_cut_off_by_the_token_limit_raises_invalid_response
        stub_google(candidates: [{ finishReason: 'MAX_TOKENS', content: { parts: [{ text: '{"score": ' }] } }])

        error = assert_raises(BaseProvider::InvalidResponseError) { call_google }

        assert_includes error.message, 'MAX_TOKENS'
      end

      def test_answer_without_text_raises_invalid_response
        stub_google(candidates: [{ finishReason: 'OTHER' }])

        assert_raises(BaseProvider::InvalidResponseError) { call_google }
      end

      def test_answer_that_is_not_json_raises_invalid_response
        stub_google(candidates: [{ finishReason: 'STOP', content: { parts: [{ text: 'Sure! The score is 8.' }] } }])

        assert_raises(BaseProvider::InvalidResponseError) { call_google }
      end

      def test_answer_wrapped_in_an_array_is_unwrapped
        stub_answer('[{"score": 8}]')

        assert_equal({ 'score' => 8 }, call_google)
      end

      def test_answer_shaped_like_the_schema_is_unwrapped
        stub_answer('[{"type": "object", "properties": {"score": 8}}]')

        assert_equal({ 'score' => 8 }, call_google)
      end

      def test_answer_nested_in_an_input_schema_is_unwrapped
        stub_answer('{"input_schema": {"properties": {"score": 8}}}')

        assert_equal({ 'score' => 8 }, call_google)
      end

      def test_answer_that_is_an_empty_json_array_raises_invalid_response
        stub_answer('[]')

        error = assert_raises(BaseProvider::InvalidResponseError) { call_google }

        assert_includes error.message, 'not a JSON object'
      end

      def test_request_without_logprobs_does_not_ask_for_them
        stub_answer('{"score": 8}')

        call_google

        assert_requested(:post, /generativelanguage\.googleapis\.com/) do |req|
          assert_equal({ 'response_mime_type' => 'application/json', 'temperature' => 0.1 },
                       JSON.parse(req.body)['generationConfig'])
        end
      end

      def test_modules_surface_the_refusal_instead_of_crashing
        stub_google(promptFeedback: { blockReason: 'SAFETY' })

        assert_raises(BaseProvider::RefusalError) do
          ActiveGenie::Lister.call('theme', config: { providers: { google: { api_key: 'test_key' } } })
        end
      end

      def test_calculate_continuous_score_helpers
        logprobs_result = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '": ' }, { 'token' => '8' }],
          'topCandidates' => [
            { 'candidates' => [{ 'token' => 'score' }] },
            { 'candidates' => [{ 'token' => '": ' }] },
            {
              'candidates' => [
                { 'token' => '8', 'logProbability' => -0.22314 },
                { 'token' => '7', 'logProbability' => -1.60943 }
              ]
            }
          ]
        }

        candidates = @provider.extract_field_logprobs(logprobs_result, 'score')

        refute_nil candidates

        score_res = @provider.calculate_continuous_score(candidates, min_score: 1.0, max_score: 10.0)

        refute_nil score_res
        assert_in_delta 7.8, score_res.expected_value, 0.1
        assert_in_delta 0.7556, score_res.normalized_score, 0.02
      end

      private

      def stub_google(body)
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(body: { usageMetadata: { promptTokenCount: 1 }, **body }.to_json)
      end

      def stub_answer(text)
        stub_google(candidates: [{ finishReason: 'STOP', content: { parts: [{ text: }] } }])
      end

      def call_google
        @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION)
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/unified_provider'
require 'webmock/minitest'

module ActiveGenie
  module Providers
    class UnifiedProviderTest < Minitest::Test
      def setup
        ActiveGenie.configuration.providers.all.each do |provider_name, provider|
          provider.api_key = "#{provider_name}_secret"
          fixture_path = "#{__dir__}/../fixtures/function_call_#{provider_name}.json"
          stub_request(:post, /#{provider.api_url}.*$/).to_return(status: 200, body: File.read(fixture_path))
        end
      end

      def test_openai_function_calling
        messages = [{ role: 'user', content: 'Test message' }]
        function = {
          name: 'test_function',
          description: 'Test function',
          parameters: {
            type: 'object',
            properties: {
              test_field: { type: 'string' },
              number_field: { type: 'integer' }
            }
          }
        }

        config = build_config('openai')
        ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['messages'], { 'role' => 'user', 'content' => 'Test message' }
          assert_equal 'test_function', request_body.dig('tools', 0, 'function', 'name')
          assert request_body.dig('tools', 0, 'function', 'parameters', 'properties').key?('test_field')
          assert request_body.dig('tools', 0, 'function', 'parameters', 'properties').key?('number_field')

          true
        end
      end

      def test_anthropic_function_calling
        messages = [{ role: 'user', content: 'Test message' }]
        function = {
          name: 'test_function',
          description: 'Test function',
          parameters: {
            type: 'object',
            properties: {
              test_field: { type: 'string' },
              number_field: { type: 'integer' }
            }
          }
        }

        config = build_config('anthropic')
        ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)

          assert_equal 'user', request_body['messages'][0]['role']
          assert_equal 'Test message', request_body['messages'][0]['content']
          assert request_body.key?('tools')
          assert_equal 1, request_body['tools'].length

          tool = request_body['tools'].first
          assert_equal 'test_function', tool['name']
          assert tool['input_schema'].key?('properties')

          properties = tool['input_schema']['properties']
          assert properties.key?('test_field')
          assert properties.key?('number_field')

          true
        end
      end

      def test_google_function_calling
        messages = [{ role: 'user', content: 'Test message' }]
        function = {
          name: 'test_function',
          description: 'Test function',
          parameters: {
            type: 'object',
            properties: {
              test_field: { type: 'string' },
              number_field: { type: 'integer' }
            }
          }
        }

        config = build_config('google')
        ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_requested(:post,
                         %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent}) do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['contents'], { 'role' => 'user', 'parts' => [{ 'text' => 'Test message' }] }
          
          schema_message = request_body['contents'].find do |content|
            content['parts'][0]['text'].include?('JSON schema') &&
              content['parts'][0]['text'].include?('test_field') &&
              content['parts'][0]['text'].include?('number_field')
          end
          assert schema_message, 'Expected to find a message containing JSON schema with test_field and number_field'

          true
        end
      end

      def test_deepseek_function_calling
        messages = [{ role: 'user', content: 'Test message' }]
        function = {
          name: 'test_function',
          description: 'Test function',
          parameters: {
            type: 'object',
            properties: {
              test_field: { type: 'string' },
              number_field: { type: 'integer' }
            }
          }
        }

        config = build_config('deepseek')
        ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['messages'], { 'role' => 'user', 'content' => 'Test message' }
          assert_equal 'test_function', request_body.dig('tools', 0, 'function', 'name')
          assert request_body.dig('tools', 0, 'function', 'parameters', 'properties').key?('test_field')
          assert request_body.dig('tools', 0, 'function', 'parameters', 'properties').key?('number_field')

          true
        end
      end

      def test_invalid_provider_raises_error
        messages = [{ role: 'user', content: 'Test message' }]
        function = { name: 'test_function' }

        config = build_config('invalid_provider')

        assert_raises(ActiveGenie::InvalidProviderError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)
        end
      end

      def test_missing_model_uses_recommended_model
        messages = [{ role: 'user', content: 'Test message' }]
        function = { name: 'test_function' }

        config = build_config('openai')
        config.llm.model = nil
        config.llm.recommended_model = 'gpt-5'

        ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_equal 'gpt-5', config.llm.model
      end

      def test_missing_model_without_recommended_raises_error
        messages = [{ role: 'user', content: 'Test message' }]
        function = { name: 'test_function' }

        config = build_config('openai')
        config.llm.model = nil
        config.llm.recommended_model = nil

        assert_raises(ActiveGenie::InvalidModelError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)
        end
      end

      def test_response_normalization
        messages = [{ role: 'user', content: 'Test message' }]
        function = { name: 'test_function' }

        # Stub a response with values that should be normalized to nil
        stub_request(:post, /api\.openai\.com.*$/).to_return(
          status: 200,
          body: {
            choices: [
              {
                message: {
                  tool_calls: [
                    {
                      function: {
                        arguments: JSON.dump({
                          field_null: 'null',
                          field_none: 'none',
                          field_undefined: 'undefined',
                          field_empty: '',
                          field_unknown: 'unknown',
                          field_unknown_brackets: '<unknown>',
                          field_valid: 'valid_value'
                        })
                      }
                    }
                  ]
                }
              }
            ]
          }.to_json
        )

        config = build_config('openai')
        result = ActiveGenie::Providers::UnifiedProvider.function_calling(messages, function, config:)

        assert_nil result['field_null']
        assert_nil result['field_none']
        assert_nil result['field_undefined']
        assert_nil result['field_empty']
        assert_nil result['field_unknown']
        assert_nil result['field_unknown_brackets']
        assert_equal 'valid_value', result['field_valid']
      end

      private

      def build_config(provider_name)
        config_hash = { provider_name: provider_name }
        config = ActiveGenie.configuration.merge(config_hash)
        config.llm.model = 'test-model'
        config
      end
    end
  end
end
# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Lister
    class JuriesTest < Minitest::Test
      def test_returns_juries_and_reasoning_normally
        stub_openai_response(
          why_these_juries: 'These are the best juries because...',
          juries: ['Writer', 'Designer', 'Editor']
        )

        result = Juries.call(
          'API documentation draft',
          'Evaluate clarity',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal ['Writer', 'Designer', 'Editor'], result.data
        assert_equal 'These are the best juries because...', result.reasoning
      end

      def test_handles_stringified_array_response
        stub_openai_response(
          why_these_juries: 'These are selected juries.',
          juries: '[ "Writer", "Designer", "Editor" ]'
        )

        result = Juries.call(
          'API documentation draft',
          'Evaluate clarity',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal ['Writer', 'Designer', 'Editor'], result.data
        assert_equal 'These are selected juries.', result.reasoning
      end

      def test_handles_comma_separated_string_response
        stub_openai_response(
          why_these_juries: 'Comma separated selection',
          juries: 'Writer, Designer, Editor'
        )

        result = Juries.call(
          'API documentation draft',
          'Evaluate clarity',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal ['Writer', 'Designer', 'Editor'], result.data
      end

      private

      def stub_openai_response(why_these_juries:, juries:)
        arguments_json = {
          why_these_juries: why_these_juries,
          juries: juries
        }.to_json

        response_body = {
          choices: [
            {
              message: {
                role: 'assistant',
                content: nil,
                tool_calls: [
                  {
                    id: 'call_123',
                    type: 'function',
                    function: {
                      name: 'identify_jury',
                      arguments: arguments_json
                    }
                  }
                ]
              }
            }
          ]
        }.to_json

        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .to_return(status: 200, body: response_body)
      end
    end
  end
end

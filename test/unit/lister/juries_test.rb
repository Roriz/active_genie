# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Lister
    class JuriesTest < Minitest::Test
      # Critical Path: Basic Execution & HTTP Payload Verification
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

        assert_instance_of ActiveGenie::Result, result
        assert_equal ['Writer', 'Designer', 'Editor'], result.data
        assert_equal 'These are the best juries because...', result.reasoning
        assert_instance_of Hash, result.metadata
        assert_equal ['Writer', 'Designer', 'Editor'], result.metadata['juries']

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions', times: 1) do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']
          tools = request_body['tools']

          assert messages.any? { |m| m['role'] == 'user' && m['content'].include?('<criteria> Evaluate clarity</criteria>') }
          assert messages.any? { |m| m['role'] == 'user' && m['content'].include?('<text-to-score>API documentation draft</text-to-score>') }

          identify_tool = tools.find { |t| t['function']['name'] == 'identify_jury' }
          refute_nil identify_tool
          params = identify_tool['function']['parameters']['properties']
          assert params.key?('why_these_juries')
          assert params.key?('juries')
        end
      end

      # Critical Path: Stringified JSON Array Parsing
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

      # Critical Path: Comma Separated String Parsing & Normalization
      def test_handles_comma_separated_string_with_extra_spaces_and_empties
        stub_openai_response(
          why_these_juries: 'Comma separated selection with spaces',
          juries: ' Writer , , Designer , Editor , '
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

      # Critical Path: Edge Case Parsing (Missing Keys, Non-String Elements)
      def test_handles_missing_or_nil_juries_response
        stub_openai_response(
          why_these_juries: 'No suitable juries identified',
          juries: nil
        )

        result = Juries.call(
          'Unusual text content',
          'Evaluate style',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal [], result.data
        assert_equal 'No suitable juries identified', result.reasoning
      end

      def test_normalizes_non_string_and_whitespace_elements
        stub_openai_response(
          why_these_juries: 'Mixed element type array',
          juries: [101, nil, '  Code Architect  ', '']
        )

        result = Juries.call(
          'Code review notes',
          'Evaluate architecture',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal ['101', 'Code Architect'], result.data
      end

      # Critical Path: Module Configuration & Delegation
      def test_module_config_recommended_model
        juries_instance = Juries.new('text', 'criteria')
        config = juries_instance.send(:module_config)

        assert_equal({ llm: { recommended_model: 'deepseek-chat' } }, config)
      end

      def test_lister_with_juries_delegation
        stub_openai_response(
          why_these_juries: 'Delegation test',
          juries: ['Architect', 'Auditor']
        )

        result = ActiveGenie::Lister.with_juries(
          'Text',
          'Criteria',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal ['Architect', 'Auditor'], result.data
        assert_equal 'Delegation test', result.reasoning
      end

      private

      def stub_openai_response(why_these_juries:, juries:)
        arguments_json = {
          why_these_juries: why_these_juries,
          juries: juries
        }.compact.to_json

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


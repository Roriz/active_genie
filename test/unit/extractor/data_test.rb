# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Extractor
    class DataTest < Minitest::Test
      def setup
        @text = "My name is John Doe, I'm 25 years old and I work as a software engineer."
        @schema = {
          name: { type: 'string', description: 'Full name of person' },
          age: { type: 'integer', description: 'Age in years' },
          profession: { type: 'string', description: 'Occupation' }
        }
      end

      # Critical Path: OpenAI Provider Integration & Schema Payload Verification
      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-openai.json")
        )

        result = Data.call(
          @text,
          @schema,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result
        assert_equal 'John Doe', result.data['name']
        assert_equal 25, result.data['age']

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']
          tool = request_body.dig('tools', 0, 'function')

          assert_equal 'data_extractor', tool['name']
          assert_includes messages, { 'role' => 'user', 'content' => @text }

          props = tool.dig('parameters', 'properties')
          assert props.key?('name')
          assert props.key?('age')
          assert props.key?('profession')
          refute props.key?('name_explanation')

          required = tool.dig('parameters', 'required')
          assert_equal %w[name age profession], required
        end
      end

      # Critical Path: Anthropic Provider Integration
      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-anthropic.json")
        )

        result = Data.call(
          @text,
          @schema,
          config: {
            llm: { provider: 'anthropic' },
            providers: { anthropic: { api_key: 'test_key' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result
        assert_equal 'John Doe', result.data['name']
        assert_equal 25, result.data['age']

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)
          tool = request_body.dig('tools', 0)

          assert_equal 'data_extractor', tool['name']
          props = tool.dig('input_schema', 'properties')
          assert props.key?('name')
          assert props.key?('age')
          assert props.key?('profession')
        end
      end

      # Critical Path: Google Provider Integration
      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-google.json")
        )

        result = Data.call(
          @text,
          @schema,
          config: {
            llm: { provider: 'google' },
            providers: { google: { api_key: 'test_key' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result
        assert_equal 'John Doe', result.data['name']
        assert_equal 25, result.data['age']
      end

      # Critical Path: DeepSeek Provider Integration
      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-deepseek.json")
        )

        result = Data.call(
          @text,
          @schema,
          config: {
            llm: { provider: 'deepseek' },
            providers: { deepseek: { api_key: 'test_key' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result
        assert_equal 'John Doe', result.data['name']
        assert_equal 25, result.data['age']
      end

      # Critical Path: Response Formatting & Nil Compacting
      def test_compacts_nil_values_in_extracted_data
        stub_openai_response({
          'name' => 'John Doe',
          'age' => nil,
          'profession' => 'Software Engineer'
        })

        result = Data.call(
          @text,
          @schema,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        # nil value for 'age' should be removed from result.data via .compact
        assert_equal({ 'name' => 'John Doe', 'profession' => 'Software Engineer' }, result.data)
        refute_includes result.data.keys, 'age'

        # metadata retains the raw response including nil values
        assert_nil result.metadata['age']
      end

      # Critical Path: Module Configuration & Delegation
      def test_module_config_recommended_model
        data_instance = Data.new(@text, @schema)
        config = data_instance.send(:module_config)

        assert_equal({ llm: { recommended_model: 'deepseek-chat' } }, config)
      end

      def test_extractor_data_module_delegation
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-openai.json")
        )

        result = ActiveGenie::Extractor.data(
          @text,
          @schema,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'test_key' } }
          }
        )

        assert_equal 'John Doe', result.data['name']
        assert_equal 25, result.data['age']
      end

      private

      def stub_openai_response(extracted_hash)
        body = {
          choices: [
            {
              message: {
                tool_calls: [
                  {
                    function: {
                      name: 'data_extractor',
                      arguments: JSON.generate(extracted_hash)
                    }
                  }
                ]
              }
            }
          ],
          usage: {
            prompt_tokens: 100,
            completion_tokens: 50,
            total_tokens: 150
          }
        }.to_json

        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .to_return(status: 200, body:)
      end
    end
  end
end


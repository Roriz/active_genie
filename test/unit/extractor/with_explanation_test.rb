# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Extractor
    class WithExplanationTest < Minitest::Test
      def setup
        @text = "My name is John Doe, I'm 25 years old and I work as a software engineer."
        @schema = {
          name: { type: 'string' },
          age: { type: 'integer' },
          profession: { type: 'string' }
        }
      end

      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-openai.json")
        )

        result = ActiveGenie::Extractor.with_explanation(
          @text,
          @schema,
          config: {
            llm: { provider: 'openai' },
            providers: {
              openai: { api_key: 'your_api_key' }
            }
          }
        )

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['messages'], { 'role' => 'user', 'content' => @text }

          function_properties = request_body.dig('tools', 0, 'function', 'parameters', 'properties')

          assert function_properties.key?('name')
          assert function_properties.key?('name_explanation')
          assert function_properties.key?('age')
          assert function_properties.key?('age_explanation')
          assert function_properties.key?('profession')
          assert function_properties.key?('profession_explanation')

          true
        end

        expected_data = {
          name: 'John Doe',
          age: 25,
          profession: 'Software Engineer'
        }

        assert_equal expected_data, result.data
      end

      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-google.json")
        )

        result = ActiveGenie::Extractor.with_explanation(
          @text,
          @schema,
          config: {
            llm: { provider: 'google' },
            providers: {
              google: { api_key: 'your_api_key' }
            }
          }
        )

        assert_requested(:post,
                         %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent}) do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['contents'], { 'role' => 'user', 'parts' => [{ 'text' => @text }] }
          assert(request_body['contents'].find do |c|
                   c['parts'][0]['text'].include?('name') && c['parts'][0]['text'].include?('name_explanation')
                 end)

          true
        end

        expected_data = {
          name: 'John Doe',
          age: 25,
          profession: 'software engineer'
        }

        assert_equal expected_data, result.data
      end

      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-anthropic.json")
        )

        result = ActiveGenie::Extractor.with_explanation(
          @text,
          @schema,
          config: {
            llm: { provider: 'anthropic' },
            providers: {
              anthropic: { api_key: 'your_api_key' }
            }
          }
        )

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)

          assert_equal 'user', request_body['messages'][0]['role']
          assert_equal @text, request_body['messages'][0]['content']

          assert request_body.key?('tools')
          assert_equal 1, request_body['tools'].length

          tool = request_body['tools'].first

          assert_equal 'data_extractor', tool['name']
          parameters = tool['input_schema']

          assert parameters.key?('properties')
          properties = parameters['properties']

          assert properties.key?('name')
          assert properties.key?('name_explanation')
          assert properties.key?('age')
          assert properties.key?('age_explanation')
          assert properties.key?('profession')
          assert properties.key?('profession_explanation')

          true
        end

        expected_data = {
          name: 'John Doe',
          age: 25,
          profession: 'software engineer'
        }

        assert_equal expected_data, result.data
      end

      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/extractor-deepseek.json")
        )

        result = ActiveGenie::Extractor.with_explanation(
          @text,
          @schema,
          config: {
            llm: { provider: 'deepseek' },
            providers: {
              deepseek: { api_key: 'your_api_key' }
            }
          }
        )

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)

          assert_includes request_body['messages'], { 'role' => 'user', 'content' => @text }

          function_properties = request_body.dig('tools', 0, 'function', 'parameters', 'properties')

          assert function_properties.key?('name')
          assert function_properties.key?('name_explanation')
          assert function_properties.key?('age')
          assert function_properties.key?('age_explanation')
          assert function_properties.key?('profession')
          assert function_properties.key?('profession_explanation')

          true
        end

        expected_data = {
          name: 'John Doe',
          age: 25,
          profession: 'software engineer'
        }

        assert_equal expected_data, result.data
      end
    end
  end
end

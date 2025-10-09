# frozen_string_literal: true

require_relative 'test_helper'
require 'webmock/minitest'

module ActiveGenie
  class ConfigurationTest < Minitest::Test
    def test_global_provider_configuration
      stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
        status: 200,
        body: File.read("#{__dir__}/fixtures/extractor-openai.json")
      )

      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(
        text,
        schema,
        config: {
          providers: { openai: { api_key: 'google_secret' } }
        }
      )

      assert_requested(:post, 'https://api.openai.com/v1/chat/completions')
    end

    def test_overwrite_global_provider_configuration
      stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
        status: 200,
        body: File.read("#{__dir__}/fixtures/extractor-google.json")
      )

      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(
        text,
        schema,
        config: {
          llm: { provider_name: 'google' },
          providers: { google: { api_key: 'google_secret' } }
        }
      )

      assert_requested(:post,
                       %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent})
    end

    def test_overwrite_global_provider_configuration_verbose
      stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
        status: 200,
        body: File.read("#{__dir__}/fixtures/extractor-google.json")
      )

      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(
        text,
        schema,
        config: {
          providers: { default: 'google', google: { api_key: 'google_secret' } }
        }
      )

      assert_requested(:post,
                       %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent})
    end

    def test_additional_context
      stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
        status: 200,
        body: File.read("#{__dir__}/fixtures/extractor-google.json")
      )

      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(
        text,
        schema,
        config: {
          providers: { google: { api_key: 'google_secret' } },
          log: {
            additional_context: { test_custom_attr: 'test' },
            output: lambda do |log|
              assert_equal 'test', log[:test_custom_attr]
            end
          }
        }
      )
    end
  end
end

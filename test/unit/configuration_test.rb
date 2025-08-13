# frozen_string_literal: true

require_relative 'test_helper'
require 'webmock/minitest'

module ActiveGenie
  class ConfigurationTest < Minitest::Test
    def setup
      ActiveGenie.configuration.providers.all.each do |provider_name, provider|
        fixture_path = "#{__dir__}/data_extractor/fixtures/generalist/#{provider_name}.json"
        stub_request(:post, /#{provider.api_url}.*$/).to_return(status: 200, body: File.read(fixture_path))
      end

      ActiveGenie.configure do |config|
        config.providers.default = 'openai'
        config.providers.openai.api_key = 'your_api_key'
      end
    end

    def test_global_provider_configuration
      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(text, schema)

      assert_requested(:post, 'https://api.openai.com/v1/chat/completions')
    end

    def test_overwrite_global_provider_configuration
      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(text, schema, config: { provider: 'google' })

      assert_requested(:post,
                       %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent})
    end

    def test_overwrite_global_provider_configuration_verbose
      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(text, schema, config: { providers: { default: 'google' } })

      assert_requested(:post,
                       %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent})
    end

    def test_additional_context
      text = 'Input Text'
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::Extractor.with_explanation(
        text,
        schema,
        config: {
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

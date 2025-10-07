# frozen_string_literal: true

require_relative 'provider_base'

module ActiveGenie
  module Config
    module Providers
      # Configuration class for the OpenAI API client.
      # Manages API keys, organization IDs, URLs, model selections, and client instantiation.
      class OpenaiConfig < ProviderBase
        NAME = :openai

        # Retrieves the API key.
        # Falls back to the OPENAI_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV.fetch('OPENAI_API_KEY', nil)
        end

        # Retrieves the base API URL for OpenAI API.
        # Defaults to 'https://api.openai.com/v1'.
        # @return [String] The API base URL.
        def api_url
          @api_url || 'https://api.openai.com/v1'
        end

        def valid_model?(model)
          model.include?('gpt')
        end

        def default_model
          'gpt-5-mini'
        end
      end
    end
  end
end

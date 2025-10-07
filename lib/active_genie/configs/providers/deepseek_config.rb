# frozen_string_literal: true

require_relative 'provider_base'

module ActiveGenie
  module Config
    module Providers
      # Configuration class for the DeepSeek API client.
      # Manages API keys, organization IDs, URLs, model selections, and client instantiation.
      class DeepseekConfig < ProviderBase
        NAME = :deepseek

        # Retrieves the API key.
        # Falls back to the DEEPSEEK_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV.fetch('DEEPSEEK_API_KEY', nil)
        end

        # Retrieves the base API URL for DeepSeek API.
        # Defaults to 'https://api.deepseek.com/v1'.
        # @return [String] The API base URL.
        def api_url
          @api_url || 'https://api.deepseek.com/v1'
        end

        def valid_model?(model)
          model.include?('deepseek')
        end

        def default_model
          'deepseek-chat'
        end
      end
    end
  end
end

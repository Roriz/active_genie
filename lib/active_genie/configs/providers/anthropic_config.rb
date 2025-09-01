# frozen_string_literal: true

require_relative 'provider_base'

module ActiveGenie
  module Config
    module Providers
      # Configuration class for the Anthropic API client.
      # Manages API keys, URLs, model selections, and client instantiation.
      class AnthropicConfig < ProviderBase
        NAME = :anthropic

        # Retrieves the API key.
        # Falls back to the ANTHROPIC_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV.fetch('ANTHROPIC_API_KEY', nil)
        end

        # Retrieves the base API URL for Anthropic API.
        # Defaults to 'https://api.anthropic.com'.
        # @return [String] The API base URL.
        def api_url
          @api_url || 'https://api.anthropic.com'
        end

        # Retrieves the Anthropic version.
        # Defaults to '2023-06-01'.
        # @return [String] The Anthropic version.
        def anthropic_version
          @anthropic_version || '2023-06-01'
        end
      end
    end
  end
end

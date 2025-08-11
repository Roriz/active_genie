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

        # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
        # Defaults to 'claude-3-haiku'.
        # @return [String] The lower tier model name.
        def lower_tier_model
          @lower_tier_model || 'claude-3-5-haiku-20241022'
        end

        # Retrieves the model name designated for the middle tier (e.g., balanced performance).
        # Defaults to 'claude-3-sonnet'.
        # @return [String] The middle tier model name.
        def middle_tier_model
          @middle_tier_model || 'claude-3-7-sonnet-20250219'
        end

        # Retrieves the model name designated for the upper tier (e.g., most capable).
        # Defaults to 'claude-3-opus'.
        # @return [String] The upper tier model name.
        def higher_tier_model
          @higher_tier_model || 'claude-3-opus-20240229'
        end
      end
    end
  end
end

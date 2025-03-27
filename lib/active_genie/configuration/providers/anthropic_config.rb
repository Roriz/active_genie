require_relative '../../clients/anthropic_client'
require_relative './base_config'

module ActiveGenie
  module Configuration::Providers
    # Configuration class for the Anthropic API client.
    # Manages API keys, URLs, model selections, and client instantiation.
    class AnthropicConfig < BaseConfig
      NAME = :anthropic

      # Retrieves the API key.
      # Falls back to the ANTHROPIC_API_KEY environment variable if not set.
      # @return [String, nil] The API key.
      def api_key
        @api_key || ENV['ANTHROPIC_API_KEY']
      end

      # Retrieves the base API URL for Anthropic API.
      # Defaults to 'https://api.anthropic.com'.
      # @return [String] The API base URL.
      def api_url
        @api_url || 'https://api.anthropic.com'
      end

      # Lazily initializes and returns an instance of the AnthropicClient.
      # Passes itself (the config object) to the client's constructor.
      # @return [ActiveGenie::Clients::AnthropicClient] The client instance.
      def client
        @client ||= ::ActiveGenie::Clients::AnthropicClient.new(self)
      end

      # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
      # Defaults to 'claude-3-haiku'.
      # @return [String] The lower tier model name.
      def lower_tier_model
        @lower_tier_model || 'claude-3-haiku'
      end

      # Retrieves the model name designated for the middle tier (e.g., balanced performance).
      # Defaults to 'claude-3-sonnet'.
      # @return [String] The middle tier model name.
      def middle_tier_model
        @middle_tier_model || 'claude-3-sonnet'
      end

      # Retrieves the model name designated for the upper tier (e.g., most capable).
      # Defaults to 'claude-3-opus'.
      # @return [String] The upper tier model name.
      def upper_tier_model
        @upper_tier_model || 'claude-3-opus'
      end
    end
  end
end
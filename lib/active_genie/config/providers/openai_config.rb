# frozen_string_literal: true

require_relative './provider_base'

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
          @api_key || ENV['OPENAI_API_KEY']
        end

        # Retrieves the base API URL for OpenAI API.
        # Defaults to 'https://api.openai.com/v1'.
        # @return [String] The API base URL.
        def api_url
          @api_url || 'https://api.openai.com/v1'
        end

        # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
        # Defaults to 'gpt-4o-mini'.
        # @return [String] The lower tier model name.
        def lower_tier_model
          @lower_tier_model || 'gpt-4.1-mini'
        end

        # Retrieves the model name designated for the middle tier (e.g., balanced performance).
        # Defaults to 'gpt-4o'.
        # @return [String] The middle tier model name.
        def middle_tier_model
          @middle_tier_model || 'gpt-4.1'
        end

        # Retrieves the model name designated for the upper tier (e.g., most capable).
        # Defaults to 'o1-preview'.
        # @return [String] The upper tier model name.
        def upper_tier_model
          @upper_tier_model || 'o3-mini'
        end
      end
    end
  end
end

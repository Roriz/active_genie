# frozen_string_literal: true

require_relative './provider_base'

module ActiveGenie
  module Config
    module Providers
      # Configuration class for the Google Generative Language API client.
      # Manages API keys, URLs, model selections, and client instantiation.
      class GoogleConfig < ProviderBase
        NAME = :google

        # Retrieves the API key.
        # Falls back to the GENERATIVE_LANGUAGE_GOOGLE_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV['GENERATIVE_LANGUAGE_GOOGLE_API_KEY'] || ENV['GEMINI_API_KEY']
        end

        # Retrieves the base API URL for Google Generative Language API.
        # Defaults to 'https://generativelanguage.googleapis.com'.
        # @return [String] The API base URL.
        def api_url
          # NOTE: Google Generative Language API uses a specific path structure like /v1beta/models/{model}:generateContent
          # The base URL here should be just the domain part.
          @api_url || 'https://generativelanguage.googleapis.com'
        end

        # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
        # Defaults to 'gemini-2.0-flash-lite'.
        # @return [String] The lower tier model name.
        def lower_tier_model
          @lower_tier_model || 'gemini-2.0-flash-lite'
        end

        # Retrieves the model name designated for the middle tier (e.g., balanced performance).
        # Defaults to 'gemini-2.0-flash'.
        # @return [String] The middle tier model name.
        def middle_tier_model
          @middle_tier_model || 'gemini-2.0-flash'
        end

        # Retrieves the model name designated for the upper tier (e.g., most capable).
        # Defaults to 'gemini-2.5-pro-experimental'.
        # @return [String] The upper tier model name.
        def upper_tier_model
          @upper_tier_model || 'gemini-2.5-pro-experimental'
        end
      end
    end
  end
end

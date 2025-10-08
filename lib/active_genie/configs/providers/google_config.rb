# frozen_string_literal: true

require_relative 'provider_base'

module ActiveGenie
  module Config
    module Providers
      # Configuration class for the Google Generative Language API client.
      # Manages API keys, URLs, model selections, and client instantiation.
      class GoogleConfig < ProviderBase
        # Retrieves the API key.
        # Falls back to the GENERATIVE_LANGUAGE_GOOGLE_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV['GENERATIVE_LANGUAGE_GOOGLE_API_KEY'] || ENV.fetch('GEMINI_API_KEY', nil)
        end

        # Retrieves the base API URL for Google Generative Language API.
        # Defaults to 'https://generativelanguage.googleapis.com'.
        # @return [String] The API base URL.
        def api_url
          # NOTE: Google Generative Language API uses a specific path structure like /v1beta/models/{model}:generateContent
          # The base URL here should be just the domain part.
          @api_url || 'https://generativelanguage.googleapis.com'
        end

        def default_model
          @default_model || 'gemini-2.5-flash'
        end

        def valid_model?(model)
          model.include?('gemini')
        end
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Config
    module Providers
      class ProviderBase
        NAME = :unknown

        attr_writer :api_key, :organization, :api_url, :client

        # Returns a hash representation of the configuration.
        # @param config [Hash] Additional key-value pairs to merge into the hash.
        # @return [Hash] The configuration settings as a hash.
        def to_h(config = {})
          {
            name: NAME,
            api_key:,
            api_url:,
            **config
          }
        end

        # Validates the configuration.
        # @return [Boolean] True if the configuration is valid, false otherwise.
        def valid?
          api_key && api_url
        end

        # Retrieves the API key.
        # Falls back to the OPENAI_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          raise NotImplementedError, 'Subclasses must implement this method'
        end

        # Retrieves the base API URL for OpenAI API.
        # Defaults to 'https://api.openai.com/v1'.
        # @return [String] The API base URL.
        def api_url
          raise NotImplementedError, 'Subclasses must implement this method'
        end

        # Lazily initializes and returns an instance of the OpenaiClient.
        # Passes itself (the config object) to the client's constructor.
        # @return [ActiveGenie::Clients::OpenaiClient] The client instance.
        def client
          raise NotImplementedError, 'Subclasses must implement this method'
        end
      end
    end
  end
end

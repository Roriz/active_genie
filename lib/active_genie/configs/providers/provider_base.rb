# frozen_string_literal: true

module ActiveGenie
  module Config
    module Providers
      class ProviderBase
        NAME = :unknown

        attr_writer :api_key, :organization, :api_url, :client,
                    :lower_tier_model, :middle_tier_model, :higher_tier_model

        # Maps a symbolic tier (:lower_tier, :middle_tier, :upper_tier) to a specific model name.
        # Falls back to the lower_tier_model if the tier is nil or unrecognized.
        # @param tier [Symbol, String, nil] The symbolic tier name.
        # @return [String] The corresponding model name.
        def tier_to_model(tier)
          {
            lower_tier: lower_tier_model,
            middle_tier: middle_tier_model,
            upper_tier: higher_tier_model
          }[tier&.to_sym] || lower_tier_model
        end

        # Returns a hash representation of the configuration.
        # @param config [Hash] Additional key-value pairs to merge into the hash.
        # @return [Hash] The configuration settings as a hash.
        def to_h(config = {})
          {
            name: NAME,
            api_key:,
            api_url:,
            lower_tier_model:,
            middle_tier_model:,
            higher_tier_model:,
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

        # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
        # Defaults to 'gpt-4o-mini'.
        # @return [String] The lower tier model name.
        def lower_tier_model
          raise NotImplementedError, 'Subclasses must implement this method'
        end

        # Retrieves the model name designated for the middle tier (e.g., balanced performance).
        # Defaults to 'gpt-4o'.
        # @return [String] The middle tier model name.
        def middle_tier_model
          raise NotImplementedError, 'Subclasses must implement this method'
        end

        # Retrieves the model name designated for the upper tier (e.g., most capable).
        # Defaults to 'o1-preview'.
        # @return [String] The upper tier model name.
        def higher_tier_model
          raise NotImplementedError, 'Subclasses must implement this method'
        end
      end
    end
  end
end

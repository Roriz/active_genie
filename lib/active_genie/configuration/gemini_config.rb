require_relative '../clients/gemini_client'

module ActiveGenie
  module Configuration
    # Configuration class for the Google Gemini API client.
    # Manages API keys, URLs, model selections, and client instantiation.
    class GeminiConfig
      attr_writer :api_key, :api_url, :client,
                  :lower_tier_model, :middle_tier_model, :upper_tier_model

      # Retrieves the API key.
      # Falls back to the GEMINI_API_KEY environment variable if not set.
      # @return [String, nil] The API key.
      def api_key
        @api_key || ENV['GEMINI_API_KEY']
      end

      # Retrieves the base API URL for Google Generative Language API.
      # Defaults to 'https://generativelanguage.googleapis.com'.
      # @return [String] The API base URL.
      def api_url
        # Note: Gemini uses a specific path structure like /v1beta/models/{model}:generateContent
        # The base URL here should be just the domain part.
        @api_url || 'https://generativelanguage.googleapis.com'
      end

      # Lazily initializes and returns an instance of the GeminiClient.
      # Passes itself (the config object) to the client's constructor.
      # @return [ActiveGenie::Clients::GeminiClient] The client instance.
      def client
        @client ||= ::ActiveGenie::Clients::GeminiClient.new(self)
      end

      # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
      # Defaults to 'gemini-1.5-flash-latest'.
      # @return [String] The lower tier model name.
      def lower_tier_model
        @lower_tier_model || 'gemini-1.5-flash-latest'
      end

      # Retrieves the model name designated for the middle tier (e.g., balanced performance).
      # Defaults to 'gemini-1.5-pro-latest'.
      # @return [String] The middle tier model name.
      def middle_tier_model
        @middle_tier_model || 'gemini-1.5-pro-latest'
      end

      # Retrieves the model name designated for the upper tier (e.g., most capable).
      # Defaults to 'gemini-1.5-flash-latest'.
      # @return [String] The upper tier model name.
      def upper_tier_model
        @upper_tier_model || 'gemini-1.5-flash-latest'
      end

      # Maps a symbolic tier (:lower_tier, :middle_tier, :upper_tier) to a specific model name.
      # Falls back to the lower_tier_model if the tier is nil or unrecognized.
      # @param tier [Symbol, String, nil] The symbolic tier name.
      # @return [String] The corresponding model name.
      def tier_to_model(tier)
        {
          lower_tier: lower_tier_model,
          middle_tier: middle_tier_model,
          upper_tier: upper_tier_model
        }[tier&.to_sym] || lower_tier_model
      end

      # Returns a hash representation of the configuration.
      # @param config [Hash] Additional key-value pairs to merge into the hash.
      # @return [Hash] The configuration settings as a hash.
      def to_h(config = {})
        {
          api_key: api_key,
          api_url: api_url,
          lower_tier_model: lower_tier_model,
          middle_tier_model: middle_tier_model,
          upper_tier_model: upper_tier_model,
          **config
        }
      end
    end
  end
end
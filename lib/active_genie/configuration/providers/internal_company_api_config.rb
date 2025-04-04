require_relative '../../clients/internal_company_api_client'
require_relative './base_config'

module ActiveGenie
  module Configuration::Providers
    # Configuration class for the Internal Company API client.
    # Manages API keys, URLs, model selections, and client instantiation.
    class InternalCompanyApiConfig < BaseConfig
      NAME = :internal_company_api

      # Retrieves the API key.
      # Falls back to the INTERNAL_COMPANY_API_KEY environment variable if not set.
      # @return [String, nil] The API key.
      def api_key
        @api_key || ENV['INTERNAL_COMPANY_API_KEY']
      end

      # Retrieves the base API URL for Internal Company API.
      # Defaults to 'https://api.internal-company.com/v1'.
      # @return [String] The API base URL.
      def api_url
        @api_url || 'https://api.internal-company.com/v1'
      end

      # Lazily initializes and returns an instance of the InternalCompanyApiClient.
      # Passes itself (the config object) to the client's constructor.
      # @return [ActiveGenie::Clients::InternalCompanyApiClient] The client instance.
      def client
        @client ||= ::ActiveGenie::Clients::InternalCompanyApiClient.new(self)
      end

      # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
      # Defaults to 'internal-basic'.
      # @return [String] The lower tier model name.
      def lower_tier_model
        @lower_tier_model || 'internal-basic'
      end

      # Retrieves the model name designated for the middle tier (e.g., balanced performance).
      # Defaults to 'internal-standard'.
      # @return [String] The middle tier model name.
      def middle_tier_model
        @middle_tier_model || 'internal-standard'
      end

      # Retrieves the model name designated for the upper tier (e.g., most capable).
      # Defaults to 'internal-premium'.
      # @return [String] The upper tier model name.
      def upper_tier_model
        @upper_tier_model || 'internal-premium'
      end
    end
  end
end

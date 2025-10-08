# frozen_string_literal: true

module ActiveGenie
  module Config
    module Providers
      class ProviderBase

        def initialize(api_key: nil, organization: nil, api_url: nil, default_model: nil)
          @api_key = api_key
          @organization = organization
          @api_url = api_url
          @default_model = default_model
        end

        attr_writer :api_key, :organization, :api_url, :default_model

        # Validates the configuration.
        # @return [Boolean] True if the configuration is valid, false otherwise.
        def valid?
          api_key && api_url
        end

        # Checks if the given model is valid for this provider. Example provider.valid_model?('gpt-4') => true
        # @param model [String, nil] The model name to validate.
        # @return [Boolean] True if the model is valid, false otherwise.
        def valid_model?(model)
          false
        end

        # Returns a hash representation of the configuration.
        # @param config [Hash] Additional key-value pairs to merge into the hash.
        # @return [Hash] The configuration settings as a hash.
        def to_h
          {
            api_key: @api_key,
            api_url: @api_url,
            organization: @organization,
            default_model: @default_model
          }
        end
      end
    end
  end
end

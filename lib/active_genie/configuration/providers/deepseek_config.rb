# frozen_string_literal: true

require_relative '../../clients/openai_client'
require_relative './base_config'

module ActiveGenie
  module Configuration
    module Providers
      # Configuration class for the DeepSeek API client.
      # Manages API keys, organization IDs, URLs, model selections, and client instantiation.
      class DeepseekConfig < BaseConfig
        NAME = :deepseek

        # Retrieves the API key.
        # Falls back to the DEEPSEEK_API_KEY environment variable if not set.
        # @return [String, nil] The API key.
        def api_key
          @api_key || ENV['DEEPSEEK_API_KEY']
        end

        # Retrieves the base API URL for DeepSeek API.
        # Defaults to 'https://api.deepseek.com/v1'.
        # @return [String] The API base URL.
        def api_url
          @api_url || 'https://api.deepseek.com/v1'
        end

        # Lazily initializes and returns an instance of the OpenaiClient.
        # Passes itself (the config object) to the client's constructor.
        # @return [ActiveGenie::Clients::OpenaiClient] The client instance.
        def client
          @client ||= ::ActiveGenie::Clients::OpenaiClient.new(self)
        end

        # Retrieves the model name designated for the lower tier (e.g., cost-effective, faster).
        # Defaults to 'deepseek-chat'.
        # @return [String] The lower tier model name.
        def lower_tier_model
          @lower_tier_model || 'deepseek-chat'
        end

        # Retrieves the model name designated for the middle tier (e.g., balanced performance).
        # Defaults to 'deepseek-chat'.
        # @return [String] The middle tier model name.
        def middle_tier_model
          @middle_tier_model || 'deepseek-chat'
        end

        # Retrieves the model name designated for the upper tier (e.g., most capable).
        # Defaults to 'deepseek-reasoner'.
        # @return [String] The upper tier model name.
        def upper_tier_model
          @upper_tier_model || 'deepseek-reasoner'
        end
      end
    end
  end
end

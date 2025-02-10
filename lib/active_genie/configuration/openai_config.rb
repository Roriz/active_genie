require_relative '../clients/openai_client'

module ActiveGenie::Configuration
  class OpenaiConfig
    attr_writer :api_key, :organization, :api_url, :client,
      :lower_tier_model, :middle_tier_model, :upper_tier_model

    def api_key
      @api_key || ENV['OPENAI_API_KEY']
    end

    def organization
      @organization || ENV['OPENAI_ORGANIZATION']
    end

    def lower_tier_model
      @lower_tier_model || 'gpt-4o-mini'
    end

    def middle_tier_model
      @middle_tier_model || 'gpt-4o'
    end

    def upper_tier_model
      @upper_tier_model || 'o1-preview'
    end

    def tier_to_model(tier)
      {
        lower_tier: lower_tier_model,
        middle_tier: middle_tier_model,
        upper_tier: upper_tier_model
      }[tier&.to_sym]
    end

    def api_url
      @api_url || 'https://api.openai.com/v1'
    end

    def client
      @client ||= ::ActiveGenie::Clients::OpenaiClient.new(self)
    end

    def to_h(config = {})
      {
        api_key:,
        organization:,
        api_url:,
        lower_tier_model:,
        middle_tier_model:,
        upper_tier_model:,
        **config
      }
    end
  end
end

module ActiveGenie::Configuration
  class RuntimeConfig
    attr_writer :max_tokens, :temperature, :model, :provider, :api_key, :max_retries

    def max_tokens
      @max_tokens ||= 4096
    end

    def temperature
      @temperature ||= 0.1
    end

    def model
      @model
    end

    def provider
      @provider ||= ActiveGenie.configuration.providers.default
    end

    def api_key
      @api_key
    end

    def max_retries
      @max_retries ||= 3
    end

    def to_h(config = {})
      {
        max_tokens:, temperature:, model:, provider:, api_key:, max_retries:,
      }.merge(config)
    end
  end
end

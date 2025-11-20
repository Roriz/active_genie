# frozen_string_literal: true

require_relative 'base_config'
require_relative 'providers/openai_config'
require_relative 'providers/google_config'
require_relative 'providers/anthropic_config'
require_relative 'providers/deepseek_config'

module ActiveGenie
  module Config
    class ProvidersConfig < BaseConfig
      def initialize(**args)
        @all = {
          openai: Providers::OpenaiConfig.new(**args.fetch(:openai, {})),
          google: Providers::GoogleConfig.new(**args.fetch(:google, {})),
          anthropic: Providers::AnthropicConfig.new(**args.fetch(:anthropic, {})),
          deepseek: Providers::DeepseekConfig.new(**args.fetch(:deepseek, {}))
        }
        super
      end

      def default
        @default ||= ENV.fetch('PROVIDER_NAME', nil)&.to_s&.downcase&.strip
      end

      def default=(provider)
        @default = provider&.to_s&.downcase&.strip
      end

      def all
        @all ||= {}
      end

      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

      def add(name, provider_configs)
        @all ||= {}
        Array(provider_configs).each do |provider_config|
          remove([name]) if @all.key?(name)

          @all[name] = provider_config.new
        end

        self
      end

      def remove(provider_configs)
        Array(provider_configs).each do |provider|
          @all.delete(provider::NAME)
        end

        self
      end

      def provider_name_by_model(model)
        return nil if model.nil?

        valid.find { |_, config| config.valid_model?(model) }&.first
      end

      def method_missing(method_name, *args, &)
        @all[method_name] || super
      end

      def respond_to_missing?(method_name, include_private = false)
        @all.key?(method_name) || super
      end

      def to_h
        h = {}
        @all.each do |key, config|
          h[key] = config.to_h
        end

        super.merge(h)
      end
    end
  end
end

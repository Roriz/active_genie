# frozen_string_literal: true

require_relative 'base_config'
require_relative 'providers/openai_config'
require_relative 'providers/google_config'
require_relative 'providers/anthropic_config'
require_relative 'providers/deepseek_config'

module ActiveGenie
  module Config
    class ProvidersConfig < BaseConfig
      # The providers ActiveGenie can call, with their default config classes.
      # `add` can replace one of these configs; it cannot add new providers.
      BUILT_IN = {
        openai: Providers::OpenaiConfig,
        google: Providers::GoogleConfig,
        anthropic: Providers::AnthropicConfig,
        deepseek: Providers::DeepseekConfig
      }.freeze

      # Every module call rebuilds its config from `to_h`, so a provider set to
      # nil there stays removed, and `config_class` keeps a replaced config's class.
      def initialize(**args)
        @all = BUILT_IN.each_with_object({}) do |(name, default_class), all|
          next if args.key?(name) && args[name].nil?

          settings = args.fetch(name, {}).dup
          all[name] = (settings.delete(:config_class) || default_class).new(**settings)
        end
        super
      end

      def default
        @default ||= normalize_name(ENV.fetch('PROVIDER_NAME', nil))
      end

      def default=(provider)
        @default = normalize_name(provider)
      end

      def all
        @all ||= {}
      end

      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

      # Replaces a built-in provider's config, e.g. with a subclass pointing at
      # an OpenAI-compatible gateway. Accepts a config class or instance.
      def add(name, provider_config)
        name = name.to_sym
        unless BUILT_IN.key?(name)
          raise ArgumentError, "Unknown provider #{name.inspect}. ActiveGenie can call: " \
                               "#{BUILT_IN.keys.join(', ')}. `add` replaces one of their configs."
        end

        @all[name] = provider_config.is_a?(Class) ? provider_config.new : provider_config
        self
      end

      # Removes providers by name, so they are never chosen for a call.
      def remove(names)
        Array(names).each { |name| @all.delete(name.to_sym) }
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
        providers = BUILT_IN.keys.to_h do |name|
          config = @all[name]
          [name, config&.to_h&.merge(config_class: config.class)]
        end

        super.merge(providers)
      end

      private

      def normalize_name(name)
        name.to_s.downcase.strip unless name.nil?
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Config
    class ProvidersConfig
      def initialize
        @all = {}
        @default = nil
      end

      attr_reader :all

      def default
        @default || ENV.fetch('PROVIDER_NAME', nil)
      end

      def default=(provider)
        normalized_provider = provider.to_s.downcase.strip
        @default = normalized_provider.size.positive? ? normalized_provider : nil
      end

      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

      def add(provider_configs)
        @all ||= {}
        Array(provider_configs).each do |provider_config|
          name = provider_config::NAME
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

      def merge(config_params = {})
        dup.tap do |config|
          config.default = config_params[:default] if config_params[:default]

          config_params.each do |key, provider_configs|
            next unless provider_configs.instance_of?(Hash)

            provider_configs.each do |provider_key, provider_value|
              config.all[key].send("#{provider_key}=", provider_value)
            end
          end
        end
      end

      def method_missing(method_name, *args, &)
        @all[method_name] || super
      end

      def respond_to_missing?(method_name, include_private = false)
        @all.key?(method_name) || super
      end
    end
  end
end

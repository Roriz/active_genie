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
        @default || valid.keys.first
      end

      def default=(provider)
        normalized_provider = provider.to_s.downcase.strip
        @default = normalized_provider.size.positive? ? normalized_provider : valid.keys.first
      end

      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

      def add(provider_classes)
        @all ||= {}
        Array(provider_classes).each do |provider|
          name = provider::NAME
          remove([name]) if @all.key?(name)

          @all[name] = provider.new
        end

        self
      end

      def remove(provider_classes)
        Array(provider_classes).each do |provider|
          @all.delete(provider::NAME)
        end

        self
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.add(config_params[:providers]) if config_params[:providers]
          config.default = config_params[:default] if config_params[:default]
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

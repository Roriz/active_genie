# frozen_string_literal: true

module ActiveGenie
  module Config
    class ProvidersConfig
      def initialize
        @all = {}
        @default = nil
      end

      def all
        @all
      end

      def default
        @default || valid.keys.first
      end

      def default=(provider)
        normalized_provider = provider.to_s.downcase.strip
        @default = normalized_provider.size > 0 ? normalized_provider : valid.keys.first
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
          define_singleton_method(name) do
            instance_variable_get("@#{name}") || instance_variable_set("@#{name}", @all[name])
          end
        end

        self
      end

      def remove(provider_classes)
        Array(provider_classes).each do |provider|
          @all.delete(provider::NAME)
          remove_method(provider::NAME)
        end

        self
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.add(config_params[:providers]) if config_params[:providers]
        end
      end
    end
  end
end

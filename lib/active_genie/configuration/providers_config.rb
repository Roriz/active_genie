# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class ProvidersConfig
      def initialize
        @all = {}
        @default = nil
      end

      def register(provider_class)
        @all ||= {}
        name = provider_class::NAME
        @all[name] = provider_class.new
        define_singleton_method(name) do
          instance_variable_get("@#{name}") || instance_variable_set("@#{name}", @all[name])
        end

        self
      end

      def default
        @default || @all.values.find(&:api_key).class::NAME
      end

      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

      def to_h(config = {})
        hash_all = {}
        @all.each do |name, provider|
          hash_all[name] = provider.to_h(config[name] || {})
        end
        hash_all
      end

      private

      attr_writer :default
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class ProvidersConfig
      def initialize
        @all = {}
        @default = nil
      end

      attr_writer :default

      def default
        @default || @all.values.find(&:api_key).class::NAME
      end

      def add(provider_class)
        @all ||= {}
        name = provider_class::NAME
        @all[name] = provider_class.new
        define_singleton_method(name) do
          instance_variable_get("@#{name}") || instance_variable_set("@#{name}", @all[name])
        end

        self
      end

      def remove(provider_class)
        @all.delete(provider_class::NAME)
        remove_method(provider_class::NAME)
        self
      end

      # QUESTION: rename valid to usablesl?
      def valid
        valid_provider_keys = @all.keys.select { |k| @all[k].valid? }
        @all.slice(*valid_provider_keys)
      end

    end
  end
end

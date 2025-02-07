require 'yaml'

module ActiveGenie
  module Providers
    module_function

    def register_internal_providers
      register_provider(:openai, ActiveGenie::Providers::Openai::Configuration)
    end

    def register_provider(name, provider_class)
      @providers ||= {}
      @providers[name] = provider_class.new
      define_singleton_method(name) do
        instance_variable_get("@#{name}") || instance_variable_set("@#{name}", @providers[name])
      end
    end

    def default_provider=(provider)
      @default_provider = provider
    end

    def default_provider
      @default_provider || @providers.values.first
    end

    def providers
      @providers
    end
  end
end

require_relative 'providers/openai/configuration'

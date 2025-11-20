# frozen_string_literal: true

require_relative 'call_wrapper'

module ActiveGenie
  class BaseModule
    prepend CallWrapper

    def self.call(...)
      new(...).call
    end

    def initialize(config: {})
      @initial_config = config || {}
    end

    def call
      raise NotImplementedError, 'Subclasses must implement the `call` method'
    end

    def config
      @config ||= ActiveGenie.new_configuration(
        ActiveGenie::DeepMerge.call(
          @initial_config.to_h,
          module_config
        )
      )
    end

    def module_config
      {}
    end
  end
end

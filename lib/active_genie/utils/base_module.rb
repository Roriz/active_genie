# frozen_string_literal: true

require_relative 'call_wrapper'

module ActiveGenie
  class BaseModule
    prepend CallWrapper

    def self.call(...)
      new(...).call
    end

    def call
      raise NotImplementedError, 'Subclasses must implement the `call` method'
    end
  end
end

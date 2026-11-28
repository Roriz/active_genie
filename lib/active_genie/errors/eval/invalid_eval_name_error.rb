# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A new eval was given a name that isn't snake_case (`rake "active_genie:eval:new[name]"`).
    class InvalidEvalNameError < Error
      CODE = 'AG-E206'
      MESSAGE = '%<name>s is not an eval name: eval names are snake_case, like ticket_router.'
      FIX = <<~FIX
        Use lowercase letters, digits and underscores, starting with a letter:
        `rake "active_genie:eval:new[%<suggestion>s]"`.
      FIX

      def initialize(name)
        super(name: name.to_s.inspect, suggestion: Error.snake_case(name))
      end
    end
  end
end

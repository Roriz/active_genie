# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A `list` gold names a check the engine doesn't have.
    class UnknownListCheckError < Error
      CODE = 'AG-E212'
      MESSAGE = 'A list gold uses the unknown check type %<type>s.'
      FIX = <<~FIX
        Set its "type" to one of: %<known>s. `rake active_genie:eval:check` names every row that uses
        another.
      FIX

      def initialize(type)
        super(type: type.inspect, known: Graders::List::CHECKS.keys.join(', '))
      end
    end
  end
end

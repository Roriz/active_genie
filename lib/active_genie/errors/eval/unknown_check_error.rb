# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A `fields` gold names a check the engine doesn't have.
    class UnknownCheckError < Error
      CODE = 'AG-E211'
      MESSAGE = 'A field gold uses the unknown check %<check>s.'
      FIX = <<~FIX
        Set its "check" to one of: %<known>s. `rake active_genie:eval:check` names every row and
        field that uses another.
      FIX

      def initialize(check)
        super(check: check.inspect, known: Matchers::CHECKS.join(', '))
      end
    end
  end
end

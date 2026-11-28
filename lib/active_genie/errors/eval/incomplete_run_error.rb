# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A baseline was saved from a run with missing or errored cases.
    class IncompleteRunError < Error
      CODE = 'AG-E223'
      MESSAGE = 'Replicate r%<replicate>s of %<eval>s is incomplete: %<count>s case(s) missing or errored, ' \
                'e.g. %<example>s.'
      FIX = <<~FIX
        Run `rake active_genie:eval:full EVAL=%<eval>s` again: it reruns only the missing and errored
        cases. A baseline needs every case.
      FIX

      def initialize(eval_name, replicate:, count:, example:)
        super(eval: eval_name, replicate:, count:, example:)
      end
    end
  end
end

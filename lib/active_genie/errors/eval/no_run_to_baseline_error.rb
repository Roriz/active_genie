# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A baseline was saved, but there is no full run for the current code.
    class NoRunToBaselineError < Error
      CODE = 'AG-E222'
      MESSAGE = 'There is no run of %<eval>s for the current code to save as its baseline.'
      FIX = <<~FIX
        Run `rake active_genie:eval:full EVAL=%<eval>s` first, then
        `rake active_genie:eval:save EVAL=%<eval>s`. Runs are keyed by a hash of the watched files, so
        a code change needs a new run.
      FIX

      def initialize(eval_name)
        super(eval: eval_name)
      end
    end
  end
end

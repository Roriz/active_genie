# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A baseline was saved from a run with cases still waiting for the LLM judge.
    class UnjudgedRunError < Error
      CODE = 'AG-E224'
      MESSAGE = 'Replicate r%<replicate>s of %<eval>s has %<count>s case(s) waiting for the judge.'
      FIX = <<~FIX
        Run `rake active_genie:eval:full EVAL=%<eval>s` again to judge them (only the judge is
        called for cached outputs), or pass FORCE=1 to save the baseline with them unjudged.
      FIX

      def initialize(eval_name, replicate:, count:)
        super(eval: eval_name, replicate:, count:)
      end
    end
  end
end

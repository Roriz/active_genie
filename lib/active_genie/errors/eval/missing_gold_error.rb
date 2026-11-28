# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A case that is graded has no gold to grade it against.
    class MissingGoldError < Error
      CODE = 'AG-E214'
      MESSAGE = 'The case %<eval>s/%<id>s has no gold, so it cannot be graded.'
      FIX = <<~FIX
        Add a "gold" to that row in evals/%<eval>s/datasets.jsonl, or label it with
        `rake active_genie:eval:blind EVAL=%<eval>s` and `rake active_genie:eval:label EVAL=%<eval>s`.
        `rake active_genie:eval:check EVAL=%<eval>s` lists every row without one.
      FIX

      def initialize(eval_name, id)
        super(eval: eval_name, id:)
      end
    end
  end
end

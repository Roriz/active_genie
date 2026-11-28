# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A label in gold.jsonl names a labeling pass other than "a" or "b".
    class InvalidLabelPassError < Error
      CODE = 'AG-E218'
      MESSAGE = 'evals/%<eval>s/gold.jsonl has labels with pass %<passes>s; a pass is "a" or "b".'
      FIX = <<~FIX
        Set "pass" on those lines of evals/%<eval>s/gold.jsonl to "a" (the first blind labeler) or
        "b" (the second).
      FIX

      def initialize(eval_name, passes)
        super(eval: eval_name, passes: passes.map(&:inspect).join(', '))
      end
    end
  end
end

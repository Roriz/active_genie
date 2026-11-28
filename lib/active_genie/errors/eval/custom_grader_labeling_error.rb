# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # Labeling was asked of an eval whose grader is a block, so there are no gold fields to label.
    class CustomGraderLabelingError < Error
      CODE = 'AG-E219'
      MESSAGE = '%<eval>s uses a custom grader, so its rows cannot be labeled.'
      FIX = <<~FIX
        Set each row's "status" in evals/%<eval>s/datasets.jsonl by hand ("decided" to run it,
        "excluded" to skip it) instead of running `rake active_genie:eval:label`.
      FIX

      def initialize(eval_name)
        super(eval: eval_name)
      end
    end
  end
end

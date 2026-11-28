# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # An eval.rb names a grader the engine doesn't have.
    class UnknownGraderError < Error
      CODE = 'AG-E210'
      MESSAGE = '%<eval>s: unknown grader %<grader>s.'
      FIX = <<~FIX
        Set `grader` in evals/%<eval>s/eval.rb to :fields, :band, :list, :rubric or :winner, or pass a
        block `{ |output, gold, row| ... }` that returns true, false or a Hash with "pass".
      FIX

      def initialize(eval_name, grader)
        super(eval: eval_name, grader: grader.inspect)
      end
    end
  end
end

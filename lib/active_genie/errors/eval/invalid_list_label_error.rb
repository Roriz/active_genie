# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A labeling pass of a `list` eval gave something other than an array of answers.
    class InvalidListLabelError < Error
      CODE = 'AG-E221'
      MESSAGE = 'A labeling pass of %<eval>s gave list %<value>s; a list label is an array of answers.'
      FIX = <<~FIX
        Write it as a JSON array in evals/%<eval>s/gold.jsonl, for example
        "list": ["first answer", "second answer"].
      FIX

      def initialize(eval_name, value)
        super(eval: eval_name, value: value.inspect[0, 200])
      end
    end
  end
end

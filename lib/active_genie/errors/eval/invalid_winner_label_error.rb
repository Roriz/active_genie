# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A labeling pass of a `winner` eval gave a winner other than a, b or either.
    class InvalidWinnerLabelError < Error
      CODE = 'AG-E220'
      MESSAGE = 'A labeling pass of %<eval>s gave winner %<value>s; a winner is one of %<sides>s.'
      FIX = <<~FIX
        Fix that label's "winner" in evals/%<eval>s/gold.jsonl to one of %<sides>s, in the row's own
        terms (a is player_a, b is player_b).
      FIX

      def initialize(eval_name, value)
        super(eval: eval_name, value: value.inspect, sides: Graders::Winner::SIDES.join(', '))
      end
    end
  end
end

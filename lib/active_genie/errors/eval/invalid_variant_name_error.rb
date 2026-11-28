# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A `variant` in eval.rb was given a name that isn't snake_case.
    class InvalidVariantNameError < Error
      CODE = 'AG-E207'
      MESSAGE = '%<eval>s: the variant name %<name>s is not snake_case.'
      FIX = <<~FIX
        Use lowercase letters, digits and underscores, starting with a letter, in
        evals/%<eval>s/eval.rb: `variant :%<suggestion>s do |input, context| ... end`.
      FIX

      def initialize(eval_name, name)
        super(eval: eval_name, name: name.to_s.inspect, suggestion: Error.snake_case(name))
      end
    end
  end
end

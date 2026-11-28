# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A `variant` in eval.rb has no block to run.
    class VariantWithoutBlockError < Error
      CODE = 'AG-E208'
      MESSAGE = '%<eval>s: the variant %<name>s has no block, so there is nothing to run.'
      FIX = <<~FIX
        Give it the code to run, like `call`, in evals/%<eval>s/eval.rb:
        `variant :%<name>s do |input, context| ... end`.
      FIX

      def initialize(eval_name, name)
        super(eval: eval_name, name:)
      end
    end
  end
end

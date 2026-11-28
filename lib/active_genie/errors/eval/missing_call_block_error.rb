# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # An eval.rb has no `call` block, so a run has no code to call on the cases.
    class MissingCallBlockError < Error
      CODE = 'AG-E209'
      MESSAGE = 'evals/%<eval>s/eval.rb has no `call` block, so there is no code to run on the cases.'
      FIX = <<~FIX
        Add one that calls your feature and returns what it returns:

          call { |input, context| TicketRouter.new(model: context.model).call(input['text']) }
      FIX

      def initialize(eval_name)
        super(eval: eval_name)
      end
    end
  end
end

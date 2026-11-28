# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # EVAL= (or ActiveGenie::Eval.fetch) names an eval that has no evals/<name>/eval.rb.
    class UnknownEvalError < Error
      CODE = 'AG-E205'
      MESSAGE = 'There is no eval %<name>s in evals/ (evals: %<known>s).'
      FIX = <<~FIX
        Pass one of those names as EVAL=<name>, or start a new eval with
        `rake "active_genie:eval:new[%<suggestion>s]"`.
      FIX

      def initialize(name, known)
        super(name: name.to_s.inspect, known: known.empty? ? 'none yet' : known.sort.join(', '),
              suggestion: Error.snake_case(name))
      end
    end
  end
end

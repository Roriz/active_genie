# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # ActiveGenie::Eval.define ran from somewhere other than an evals/<name>/eval.rb that load! reads.
    class DefineOutsideLoadError < Error
      CODE = 'AG-E203'
      MESSAGE = 'ActiveGenie::Eval.define(%<name>s) ran outside of an evals/<name>/eval.rb file.'
      FIX = <<~FIX
        Put the define block in evals/%<folder>s/eval.rb. The rake tasks load every evals/*/eval.rb
        through ActiveGenie::Eval.load!, so don't require or load that file yourself.
      FIX

      def initialize(name)
        super(name: name.to_s.inspect, folder: Error.snake_case(name))
      end
    end
  end
end

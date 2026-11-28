# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # evals/<folder>/eval.rb defines an eval with another name.
    class EvalNameMismatchError < Error
      CODE = 'AG-E204'
      MESSAGE = 'evals/%<folder>s/eval.rb defines the eval %<name>s, but an eval is named after its folder.'
      FIX = <<~FIX
        Name it after the folder, `ActiveGenie::Eval.define '%<folder>s' do ... end`, or move the file
        to evals/%<name>s/eval.rb.
      FIX

      def initialize(folder:, name:)
        super(folder:, name: name.to_s.inspect)
      end
    end
  end
end

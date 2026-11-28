# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A line of a .jsonl file (datasets, gold, judge verdicts) isn't valid JSON.
    class InvalidJsonlError < Error
      CODE = 'AG-E215'
      MESSAGE = '%<file>s:%<line>s is not valid JSON: %<error>s'
      FIX = <<~FIX
        Each line of a .jsonl file is one JSON object. Fix line %<line>s (a trailing comma, an
        unescaped quote or a line break inside a string is the usual cause), then run
        `rake active_genie:eval:check`.
      FIX

      def initialize(file, line, error)
        super(file:, line:, error:)
      end
    end
  end
end

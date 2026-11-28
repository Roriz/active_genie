# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A case needs the LLM judge, and evals/config.yml doesn't pin one (or misses its provider or model).
    class JudgeConfigMissingError < Error
      CODE = 'AG-E216'
      MESSAGE = 'evals/config.yml has no %<missing>s, and a case needs the LLM judge.'
      FIX = <<~FIX
        Pin the judge in evals/config.yml:

          judge:
            provider: anthropic
            model: claude-sonnet-5-5

        Its verdicts are cached in evals/judge/<model>.jsonl, so keep it fixed: a new judge means a
        new baseline.
      FIX

      def initialize(missing)
        super(missing:)
      end
    end
  end
end

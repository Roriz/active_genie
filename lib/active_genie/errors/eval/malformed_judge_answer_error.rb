# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # The LLM judge answered, but not in the shape its question asks for. Nothing is cached.
    class MalformedJudgeAnswerError < Error
      CODE = 'AG-E217'
      MESSAGE = 'The judge %<model>s gave a malformed %<kind>s answer: %<answer>s'
      FIX = <<~FIX
        Nothing was cached, so the case stays unjudged; run the eval again to ask once more. If it
        keeps happening, pin a judge model that follows function calling better under judge: in
        evals/config.yml (a new judge means a new baseline).
      FIX

      def initialize(model:, kind:, answer:)
        super(model:, kind:, answer: answer.inspect[0, 200])
      end
    end
  end
end

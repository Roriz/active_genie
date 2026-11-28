# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # `config.log.add_observer` was given a scope that isn't a Hash of log fields.
  class InvalidLogScopeError < Error
    CODE = 'AG-E005'
    MESSAGE = 'config.log.add_observer takes a Hash scope, but it was given %<scope>s.'
    FIX = <<~FIX
      Pass the log fields an entry must match, or leave scope out to observe every entry:

        config.log.add_observer(scope: { code: :llm_usage }) { |log| ... }
    FIX

    def initialize(scope)
      super(scope: scope.inspect[0, 200])
    end
  end
end

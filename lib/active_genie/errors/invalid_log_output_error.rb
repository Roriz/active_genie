# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # `config.log.output` was given something it can't call with each log entry.
  class InvalidLogOutputError < Error
    CODE = 'AG-E004'
    MESSAGE = 'config.log.output must respond to `call`, but it was given %<output>s.'
    FIX = <<~FIX
      Set it to a lambda, a Proc or any object with a `call(log)` method:

        ActiveGenie.configure do |config|
          config.log.output = ->(log) { Rails.logger.info(log) }
        end
    FIX

    def initialize(output)
      super(output: output.inspect[0, 200])
    end
  end
end

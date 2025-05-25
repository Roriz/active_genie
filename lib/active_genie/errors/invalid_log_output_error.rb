# frozen_string_literal: true

module ActiveGenie
  class InvalidLogOutputError < StandardError
    TEXT = <<~TEXT
      Invalid log output option. Must be a callable object. Given: %<output>s
      Example:
        ```ruby
        ActiveGenie.configure do |config|
          config.log.output = ->(log) { puts log }
        end
        ```
    TEXT

    def initialize(output)
      super(format(TEXT, output:))
    end
  end
end

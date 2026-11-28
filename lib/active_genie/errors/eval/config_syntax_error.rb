# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # evals/config.yml isn't valid YAML.
    class ConfigSyntaxError < Error
      CODE = 'AG-E202'
      MESSAGE = '%<path>s is not valid YAML: %<error>s'
      FIX = <<~FIX
        Fix the line the YAML error names. The file is a YAML hash; the one
        `rake active_genie:eval:install` writes is the reference:

          dev:
            provider: openai
            model: gpt-6.1-terra
          judge:
            provider: anthropic
            model: claude-sonnet-5-5
      FIX

      def initialize(path, error)
        super(path:, error:)
      end
    end
  end
end

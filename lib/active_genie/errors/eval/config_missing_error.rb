# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # evals/config.yml doesn't exist under the app root.
    class ConfigMissingError < Error
      CODE = 'AG-E201'
      MESSAGE = '%<path>s is missing, so there is no eval setup to read.'
      FIX = <<~FIX
        Run `rake active_genie:eval:install` from the app root. It writes evals/config.yml,
        evals/README.md and evals/.gitignore, and never overwrites a file.
      FIX

      def initialize(path)
        super(path:)
      end
    end
  end
end

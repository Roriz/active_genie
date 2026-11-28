# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # MODE= names a run mode other than quick or full.
    class UnknownModeError < Error
      CODE = 'AG-E213'
      MESSAGE = 'Unknown eval mode %<mode>s.'
      FIX = 'Use MODE=quick (the dev pool, the default) or MODE=full (every case).'

      def initialize(mode)
        super(mode: mode.to_s.inspect)
      end
    end
  end
end

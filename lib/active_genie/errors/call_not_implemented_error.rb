# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # A subclass of ActiveGenie::BaseModule was called without defining `call`.
  class CallNotImplementedError < Error
    CODE = 'AG-E006'
    MESSAGE = '%<klass>s inherits ActiveGenie::BaseModule but does not define `call`.'
    FIX = <<~FIX
      Define `call` in %<klass>s. It sends its messages through
      ActiveGenie::Providers::UnifiedProvider.function_calling and returns an ActiveGenie::Result;
      lib/active_genie/comparator/debate.rb is a complete example.
    FIX

    def initialize(klass)
      super(klass: klass.name || klass.inspect)
    end
  end
end

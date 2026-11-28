# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # The provider declined the request or blocked the answer, for example through its safety filters.
  class RefusalError < Error
    CODE = 'AG-E104'
    MESSAGE = '%<provider>s declined the request for model %<model>s: %<detail>s'
    FIX = <<~FIX
      The provider's content rules blocked the input or the answer, so a retry of the same input gets
      the same refusal. Check the input for content the provider won't process, reword the criteria,
      or send these inputs to another provider with config.providers.default.
    FIX
  end
end

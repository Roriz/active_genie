# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # The provider answered, but not with a usable result: no tool call or text, or malformed JSON.
  class InvalidResponseError < Error
    CODE = 'AG-E105'
    MESSAGE = '%<provider>s (model %<model>s) returned an answer ActiveGenie cannot use: %<detail>s'
    FIX = <<~FIX
      This is usually a one-off from the model: retry the call, ideally from a background job. If it
      keeps happening, the model does not follow function calling reliably; pick another one with
      config.llm.model.
    FIX
  end
end

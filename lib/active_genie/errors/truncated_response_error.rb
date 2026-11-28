# frozen_string_literal: true

require_relative 'invalid_response_error'

module ActiveGenie
  # The answer was cut off at the token limit, so it is incomplete. It subclasses
  # InvalidResponseError, so `rescue ActiveGenie::InvalidResponseError` sees it.
  class TruncatedResponseError < InvalidResponseError
    CODE = 'AG-E106'
    MESSAGE = '%<provider>s (model %<model>s) cut the answer off at the token limit (%<detail>s).'
    FIX = '%<hint>s'

    # `max_tokens` is the limit the request sent, or nil when the provider applied its own.
    def initialize(provider:, model:, detail:, max_tokens: nil)
      hint = if max_tokens
               "Raise config.llm.max_tokens (it was #{max_tokens}), or send a shorter input."
             else
               "ActiveGenie sends no token limit to #{provider}, so the model hit its own output limit. " \
                 'Send a shorter input, or pick a model with a larger output limit in config.llm.model.'
             end
      super(provider:, model:, detail:, hint:)
    end
  end
end

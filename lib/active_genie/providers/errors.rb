# frozen_string_literal: true

module ActiveGenie
  module Providers
    # Errors shared by every provider. Each provider class inherits these
    # constants, so `OpenaiProvider::InvalidResponseError` and
    # `BaseProvider::InvalidResponseError` name the same class.
    class BaseProvider
      # Any non-2xx response, or a body that isn't valid JSON.
      class ProviderUnknownError < StandardError; end

      # Rate limits, request timeouts and server-side failures. These are retried
      # with backoff; subclassing ProviderUnknownError keeps existing
      # `rescue ProviderUnknownError` handlers working once retries run out.
      class ProviderTransientError < ProviderUnknownError; end

      # The provider answered, but not with a usable result: no tool call or
      # text, an answer cut off by the token limit, or malformed JSON.
      class InvalidResponseError < StandardError; end

      # The provider declined the request, for example through safety filters.
      class RefusalError < StandardError; end
    end
  end
end

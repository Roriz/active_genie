# frozen_string_literal: true

module ActiveGenie
  class ProviderServerError < StandardError
    TEXT = <<~TEXT.freeze
      Provider server error: #{code}
      #{body}

      Providers errors are common and can occur for various reasons, such as:
      - Invalid API key
      - Exceeded usage limits
      - Temporary server issues

      Be ready to handle these errors gracefully in your application. We recommend implementing retry logic and exponential backoff strategies.
      Usually async workers layer is the ideal place to handle such errors.
    TEXT

    def initialize(response)
      @response = response
      super(format(TEXT, **response))
    end
  end
end

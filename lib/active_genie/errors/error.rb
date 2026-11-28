# frozen_string_literal: true

module ActiveGenie
  # The root of every error ActiveGenie raises. Each subclass has a stable code, so you can log and
  # group failures by it, and a message that says what went wrong, how to fix it, and where the
  # errors reference explains it:
  #
  #   rescue ActiveGenie::Error => e
  #     Rails.logger.error(code: e.code, error: e.message)
  #
  # A subclass sets CODE and two `format` templates, MESSAGE and FIX, filled with the values it passes
  # to `super` as keywords.
  class Error < StandardError
    DOCS_URL = 'https://activegenie.ai/reference/errors'
    CODE = nil

    def self.code = self::CODE

    def self.docs_url = "#{DOCS_URL}##{code.downcase}"

    def initialize(**values)
      super(compose(values))
    end

    def code = self.class.code

    private

    def compose(values)
      fix = format(self.class::FIX, **values).chomp.gsub(/^(?=.)/, '  ')
      "#{format(self.class::MESSAGE, **values).chomp}\n\nHow to fix:\n#{fix}\n\nDocs: #{self.class.docs_url}"
    end
  end
end

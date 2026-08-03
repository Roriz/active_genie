# frozen_string_literal: true

module ActiveGenie
  module TextCase
    module_function

    # Maximum length accepted by provider JSON schema property keys.
    MAX_KEY_LENGTH = 64
    FALLBACK_KEY = 'unnamed'

    # Converts arbitrary text into a snake_case key safe to use as a JSON schema
    # property name. Providers validate these keys - Anthropic rejects anything
    # outside /\A[a-zA-Z0-9_.-]{1,64}\z/ - so every character outside that set is
    # replaced rather than passed through.
    #
    # Pass a smaller max_length when the caller appends a suffix to the result,
    # so the combined key still fits within the provider limit.
    def underscore(camel_cased_word, max_length: MAX_KEY_LENGTH)
      word = camel_cased_word.to_s.gsub('::', '_')
      word.gsub!(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, '_')
      word.downcase!
      word.tr!('-', '_')
      word.gsub!(/[^a-z0-9_.]+/, '_')
      word.squeeze!('_')
      word.delete_prefix!('_')
      word.delete_suffix!('_')

      word = word[0, max_length].to_s.delete_suffix('_')
      word.empty? ? FALLBACK_KEY : word
    end
  end
end

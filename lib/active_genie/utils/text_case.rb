# frozen_string_literal: true

module ActiveGenie
  module TextCase
    module_function

    def underscore(camel_cased_word)
      return camel_cased_word.to_s.dup unless /[A-Z-]|::/.match?(camel_cased_word)

      word = camel_cased_word.to_s.gsub('::', '/')
      word.gsub!(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, '_')
      word.tr!('-', '_')
      word.tr!(' ', '_')
      word.downcase!
      word
    end
  end
end

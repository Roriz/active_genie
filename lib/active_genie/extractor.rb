# frozen_string_literal: true

require_relative 'extractor/explanation'
require_relative 'extractor/data'
require_relative 'extractor/litote'

module ActiveGenie
  module Extractor
    module_function

    def call(...)
      Explanation.call(...)
    end

    def with_explanation(...)
      Explanation.call(...)
    end

    def data(...)
      Data.call(...)
    end

    def with_litote(...)
      Litote.call(...)
    end
  end
end

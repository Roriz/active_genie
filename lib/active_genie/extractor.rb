# frozen_string_literal: true

require_relative 'extractor/explanation'
require_relative 'extractor/litote'

module ActiveGenie
  module Extractor
    module_function

    def_delegator :Explanation, :call
    def_delegator :Explanation, :call, :with_explanation
    def_delegator :Litote, :call, :with_litote
  end
end

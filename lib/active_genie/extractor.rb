# frozen_string_literal: true

require 'forwardable'
require_relative 'extractor/explanation'
require_relative 'extractor/litote'

module ActiveGenie
  module Extractor
    extend Forwardable

    module_function

    def_delegator :Explanation, :call
    def_delegator :Explanation, :call, :with_explanation
    def_delegator :Litote, :call, :with_litote
  end
end

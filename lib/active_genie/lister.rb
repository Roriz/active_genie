# frozen_string_literal: true

require 'forwardable'
require_relative 'lister/feud'
require_relative 'lister/juries'

module ActiveGenie
  module Lister
    extend Forwardable

    module_function

    def_delegator :Feud, :call
    def_delegator :Feud, :call, :with_feud
    def_delegator :Juries, :call, :with_juries
  end
end

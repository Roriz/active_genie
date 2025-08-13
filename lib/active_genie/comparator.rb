# frozen_string_literal: true

require 'forwardable'
require_relative 'comparator/debate'
require_relative 'comparator/fight'

module ActiveGenie
  module Comparator
    extend Forwardable

    module_function

    ComparatorResponse = Struct.new(:winner, :loser, :reasoning, :raw, keyword_init: true)

    def_delegator :Debate, :call
    def_delegator :Debate, :call, :by_debate
    def_delegator :Fight, :call, :by_fight
  end
end

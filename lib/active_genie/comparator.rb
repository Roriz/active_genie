# frozen_string_literal: true

require_relative 'comparator/debate'
require_relative 'comparator/fight'

module ActiveGenie
  module Comparator
    module_function

    ComparatorResponse = Struct.new(:winner, :loser, :reasoning, :raw, keyword_init: true)

    def call(...)
      Debate.call(...)
    end

    def by_debate(...)
      Debate.call(...)
    end

    def by_fight(...)
      Fight.call(...)
    end
  end
end

# frozen_string_literal: true

require_relative 'ranker/tournament'
require_relative 'ranker/free_for_all'
require_relative 'ranker/elo'
require_relative 'ranker/scoring'

module ActiveGenie
  module Ranker
    module_function

    def_delegator :Tournament, :call
    def_delegator :Tournament, :call, :tournament
    def_delegator :FreeForAll, :call, :free_for_all
    def_delegator :Elo, :call, :elo
    def_delegator :Scoring, :call, :scoring
  end
end

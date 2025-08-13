# frozen_string_literal: true

require 'forwardable'
require_relative 'ranker/tournament'
require_relative 'ranker/free_for_all'
require_relative 'ranker/elo'
require_relative 'ranker/scoring'

module ActiveGenie
  module Ranker
    extend Forwardable

    module_function

    def_delegator :Tournament, :call
    def_delegator :Tournament, :call, :by_tournament
    def_delegator :FreeForAll, :call, :by_free_for_all
    def_delegator :Elo, :call, :by_elo
    def_delegator :Scoring, :call, :by_scoring
  end
end

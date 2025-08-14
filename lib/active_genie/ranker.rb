# frozen_string_literal: true

require_relative 'ranker/tournament'
require_relative 'ranker/free_for_all'
require_relative 'ranker/elo'
require_relative 'ranker/scoring'

module ActiveGenie
  module Ranker
    module_function

    def call(...)
      Tournament.call(...)
    end

    def by_tournament(...)
      Tournament.call(...)
    end

    def by_free_for_all(...)
      FreeForAll.call(...)
    end

    def by_elo(...)
      Elo.call(...)
    end

    def by_scoring(...)
      Scoring.call(...)
    end
  end
end

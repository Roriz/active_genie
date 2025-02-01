require_relative 'elo_ranking/tournament'

module ActiveGenie
  module EloRanking
    module_function

    def tournament(...)
      Tournament.call(...)
    end
  end
end

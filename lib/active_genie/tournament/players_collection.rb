require_relative '../battle/basic'
require_relative '../utils/math'
require_relative './player'

module ActiveGenie::EloRanking
  class PlayersCollection
    def initialize(param_players)
      @players = build(param_players)
    end
    attr_reader :players

    def coefficient_of_variation
      score_list = eligible.map(&:score)
      avg = score_list.sum / score_list.size
      stdev = ActiveGenie::Utils::Math.standard_deviation(score_list)

      avg / stdev
    end

    def tier_relegation
      eligible[(tier_size*-1)..-1]
    end

    def tier_defense
      eligible[(tier_size*-2)...(tier_size*-1)]
    end

    def eligible
      @players.reject(&:eliminated).sort_by(&:elo)
    end

    def eligible_size
      @players.reject(&:eliminated).size
    end

    def to_h
      @players.sort_by(&:elo).reverse.map(&:to_h)
    end

    def method_missing(...)
      @players.send(...)
    end

    private

    def build(param_players)
      param_players.map { |player| Player.new(player) }
    end

    # Returns the number of players to battle in each round
    # based on the eligible size, start fast and go slow until top 10
    # Example:
    #   - 50 eligible, tier_size: 15
    #   - 35 eligible, tier_size: 11 
    #   - 24 eligible, tier_size: 10
    #   - 14 eligible, tier_size: 4
    #  4 rounds to reach top 10 with 50 players
    def tier_size
      [[(eligible_size / 3).round, 10].max, eligible_size - 9].min
    end
  end
end
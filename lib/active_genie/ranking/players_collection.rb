require_relative './player'

module ActiveGenie::Ranking
  class PlayersCollection
    def initialize(param_players)
      @players = build(param_players)
    end
    attr_reader :players

    def coefficient_of_variation
      score_list = eligible.map(&:score)
      mean = score_list.sum.to_f / score_list.size
      return nil if mean == 0

      variance = score_list.map { |num| (num - mean) ** 2 }.sum / score_list.size
      standard_deviation = Math.sqrt(variance)

      (standard_deviation / mean) * 100
    end

    def tier_relegation
      eligible[(tier_size*-1)..-1]
    end

    def tier_defense
      eligible[(tier_size*-2)...(tier_size*-1)]
    end

    def eligible
      sorted.reject(&:eliminated)
    end

    def eligible_size
      @players.reject(&:eliminated).size
    end

    def to_h
      sorted.map.with_index(1) { |p, rank| p.to_h(rank:) }
    end

    def sorted
      @players.sort_by { |p| [-p.free_for_all_score, -(p.elo || 0), -(p.score || 0)] }
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
      [[(eligible_size / 3).ceil, 10].max, eligible_size - 10].min
    end
  end
end
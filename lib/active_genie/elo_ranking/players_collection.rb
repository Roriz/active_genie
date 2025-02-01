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
      avg = elo_list.sum / elo_list.size
      stdev = ActiveGenie::Utils::Math.standard_deviation(elo_list)

      avg / stdev
    end

    def percentile(percent)
      ActiveGenie::Utils::Math.percentile(elo_list, percent)
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

    def method_missing(...)
      @players.send(...)
    end

    def battle!(player_a, player_b, criteria, options: {})
      battle_result = ActiveGenie::Battle.basic(player_a, player_b, criteria, options: options)
      winner, loser = battle_result.values_at('winner', 'loser')
      puts battle_result

      return battle_result if winner.nil? || loser.nil?

      new_elo = ActiveGenie::Utils::Math.calculate_new_elo(winner.elo, loser.elo)
      puts "Battle #{player_a.content} (#{player_a.elo}) vs #{player_b.content} (#{player_b.elo}) = #{winner.content} (#{new_elo[0]})"
      winner.elo = new_elo[0]
      loser.elo = new_elo[1] - (options[:penalty] || 0)

      battle_result
    end

    private

    def build(param_players)
      param_players.map { |player| Player.new(player) }
    end

    def elo_list
      @players.map(&:elo)
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
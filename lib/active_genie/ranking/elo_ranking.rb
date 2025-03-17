require_relative '../battle/basic'

module ActiveGenie::Ranking
  class EloRanking
    def self.call(players, criteria, config: {})
      new(players, criteria, config:).call
    end

    def initialize(players, criteria, config: {})
      @players = players
      @criteria = criteria
      @config = config
      @start_time = Time.now
    end

    def call
      @players.each(&:generate_elo_by_score)

      round_count = 0
      while @players.eligible_size > MINIMAL_PLAYERS_TO_BATTLE
        round = create_round(@players.tier_relegation, @players.tier_defense)

        round.each do |player_a, player_b|
          winner, loser = battle(player_a, player_b) # This can take a while, can be parallelized
          update_elo(winner, loser)
          ActiveGenie::Logger.trace({ **log, step: :elo_battle, winner_id: winner.id, loser_id: loser.id, winner_elo: winner.elo, loser_elo: loser.elo })
        end

        eliminate_all_relegation_players
        round_count += 1
      end

      ActiveGenie::Logger.info({ **log, step: :elo_end, round_count:, eligible_size: @players.eligible_size })
      @players
    end

    private

    MATCHS_PER_PLAYER = 3
    LOSE_PENALTY = 15
    MINIMAL_PLAYERS_TO_BATTLE = 10
    K = 32

    # Create a round of matches
    # each round is exactly 1 regation player vs 3 defense players for all regation players
    # each match is unique (player vs player)
    # each defense player is battle exactly 3 times
    def create_round(relegation_players, defense_players)
      matches = []

      relegation_players.each do |player_a|
        player_enemies = []
        MATCHS_PER_PLAYER.times do
          defender = nil
          while defender.nil? || player_enemies.include?(defender.id)
            defender = defense_players.sample
          end

          matches << [player_a, defender].shuffle
          player_enemies << defender.id
        end
      end

      matches
    end

    def battle(player_a, player_b)
      ActiveGenie::Battle.basic(
        player_a,
        player_b,
        @criteria,
        config:
      ).values_at('winner', 'loser')
    end

    def update_elo(winner, loser)
      return if winner.nil? || loser.nil?

      new_winner_elo, new_loser_elo = calculate_new_elo(winner.elo, loser.elo)

      winner.elo = [new_winner_elo, max_defense_elo].min
      loser.elo = [new_loser_elo - LOSE_PENALTY, min_relegation_elo].max
    end

    def max_defense_elo
      @players.tier_defense.max_by(&:elo).elo
    end

    def min_relegation_elo
      @players.tier_relegation.min_by(&:elo).elo
    end

    # Read more about the formula on https://en.wikipedia.org/wiki/Elo_rating_system
    def calculate_new_elo(winner_elo, loser_elo)
      expected_score_a = 1 / (1 + 10**((loser_elo - winner_elo) / 400))
      expected_score_b = 1 - expected_score_a

      new_elo_winner = winner_elo + K * (1 - expected_score_a)
      new_elo_loser = loser_elo + K * (1 - expected_score_b)

      [new_elo_winner, new_elo_loser]
    end

    def eliminate_all_relegation_players
      eliminations = @players.tier_relegation.size
      @players.tier_relegation.each { |player| player.eliminated = 'tier_relegation' }
      ActiveGenie::Logger.trace({ **log, step: :elo_round, eligible_size: @players.eligible_size, eliminations: })
    end

    def config
      { **@config }
    end

    def log
      {
        **(@config.dig(:log) || {}),
        duration: Time.now - @start_time
      }
    end
  end
end

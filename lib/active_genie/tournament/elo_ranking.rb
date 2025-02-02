module ActiveGenie::Tournament
  class EloRanking
    def self.call(players, criteria, options: {})
      new(players, criteria, options:).call
    end

    def initialize(players, criteria, options: {})
      @players = players
      @criteria = criteria
      @options = options
    end

    def call
      @players.each(&:generate_elo_by_score)

      while @players.eligible_size > MINIMAL_PLAYERS_TO_BATTLE
        round = create_round(@players.tier_relegation, @players.tier_defense)

        round.each do |player_a, player_b|
          winner, loser = battle(player_a, player_b) # This can take a while, can be parallelized
          update_elo(winner, loser)
        end

        @players.tier_relegation.each(&:eliminate!)
      end

      @players
    end

    private

    MATCHS_PER_PLAYER = 3
    LOSE_PENALTY = 15
    MINIMAL_PLAYERS_TO_BATTLE = 10

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
        options: @options
      ).values_at('winner', 'loser')
    end

    def update_elo(winner, loser)
      return if winner.nil? || loser.nil?

      new_winner_elo, new_loser_elo = ActiveGenie::Utils::Math.calculate_new_elo(winner.elo, loser.elo)

      winner.elo = [new_winner_elo, max_defense_elo].min
      loser.elo = [new_loser_elo - LOSE_PENALTY, min_relegation_elo].max
    end

    def max_defense_elo
      @players.tier_defense.max_by(&:elo).elo
    end

    def min_relegation_elo
      @players.tier_relegation.min_by(&:elo).elo
    end
  end
end

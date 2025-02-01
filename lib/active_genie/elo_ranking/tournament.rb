require_relative './players_collection'
require_relative '../scoring/recommended_reviews'

module ActiveGenie::EloRanking
  class Tournament
    def self.call(param_players, criteria, options: {})
      new(param_players, criteria, options:).call
    end

    def initialize(param_players, criteria, options: {})
      @players = PlayersCollection.new(param_players)
      @criteria = criteria
      @options = options
    end

    def call
      puts 'Starting tournament...'
      # List of players
      @players.each do |player|
        puts "Starting player evaluation #{player.id}..."
        player.generate_score(@criteria, reviewers, options: @options) # This can take a while, can be parallelized
        player.generate_elo(BASE_ELO)
      end
      puts @players.players.map(&:to_h).to_json

      puts 'Early elimination before the tournament...'
      # Early elimination before the tournament
      if @players.coefficient_of_variation >= HIGH_ELO_VARIATION_THRESHOLD
        minimal_elo = @players.percentile(0.25)
        puts "Minimal ELO: #{minimal_elo}"
        @players.each do |player|
          player.eliminate! if player.elo < minimal_elo
        end
      end

      puts 'Tournament...'
      # Tournament
      while @players.eligible_size > 10
        puts "Round with #{@players.eligible_size} players"
        round = create_round(@players.tier_relegation, @players.tier_defense)
        round.each do |player_a, player_b|
          puts "Battle between #{player_a.id} and #{player_b.id}"
          @players.battle!(player_a, player_b, @criteria, options: battle_options) # This can take a while, can be parallelized
        end

        puts 'Eliminating players...'
        @players.tier_relegation.each(&:eliminate!)
      end

      @players.sort_by(&:elo).map(&:to_h)
    end

    private

    BASE_ELO = 1000
    HIGH_ELO_VARIATION_THRESHOLD = 0.3
    MATCHS_PER_PLAYER = 3
    LOSE_PENALTY = 15
    
    def battle_options
      { **@options, penalty: LOSE_PENALTY }
    end

    # Create a round of matches
    # each round is exactly 1 regation player vs 3 defense players for all regation players
    # each match is unique (player vs player)
    # each defense player is battle exactly 3 times
    def create_round(relegation_players, defense_players)
      matches = []
      defender_matches = {}
      defense_players.each { |player| defender_matches[player.id] = [] }

      relegation_players.each do |player_a|
        MATCHS_PER_PLAYER.times do
          defender = nil
          while defender.nil? || defender_matches[defender.id].include?(player_a.id)
            defender = defense_players.sample
          end

          matches << [player_a, defender].shuffle
          defender_matches[defender.id] << player_a.id
        end
      end

      matches
    end

    def reviewers
      [recommended_reviews['reviewer1'], recommended_reviews['reviewer2'], recommended_reviews['reviewer3']]
    end

    def recommended_reviews
      @recommended_reviews ||= ActiveGenie::Scoring::RecommendedReviews.call(
        @players.first,
        @criteria,
        options: @options
      )
    end
  end
end

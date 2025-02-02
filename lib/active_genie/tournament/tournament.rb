require_relative './players_collection'
require_relative '../scoring/recommended_reviews'

module ActiveGenie::EloRanking
  class Tournament
    def self.call(param_players, criteria, options: {})
      new(param_players, criteria, options:).call
    end

    def initialize(param_players, criteria, options: {})
      @param_players = param_players
      @criteria = criteria
      @options = options
    end

    def call
      set_initial_score_players
      eliminate_obvious_bad_players
      run_elo_ranking if @players.eligible_size > 10
      run_league

      @players.to_h
    end

    private

    HIGH_ELO_VARIATION_THRESHOLD = 0.3
    MATCHS_PER_PLAYER = 3

    def set_initial_score_players
      @players.each do |player|
        player.score = generate_score(player.content) # This can take a while, can be parallelized
      end
    end

    def generate_score(content)
      ActiveGenie::Scoring::Basic.call(content, @criteria, reviewers, options: @options)['final_score']
    end

    def eliminate_obvious_bad_players
      while @players.coefficient_of_variation >= HIGH_ELO_VARIATION_THRESHOLD
        @players.eligible.last.eliminate!
      end
    end

    def run_elo_ranking
      EloRanking.call(@players, @criteria, options: @options)
    end

    def run_league
      League.call(@players, @criteria, options: @options)
    end

    def reviewers
      [recommended_reviews['reviewer1'], recommended_reviews['reviewer2'], recommended_reviews['reviewer3']]
    end

    def recommended_reviews
      @recommended_reviews ||= ActiveGenie::Scoring::RecommendedReviews.call(
        @players.sample,
        @criteria,
        options: @options
      )
    end

    def players
      @players ||= PlayersCollection.new(@param_players)
    end
  end
end

require_relative '../clients/router.rb'
require_relative '../utils/math.rb'
require_relative './player_collection.rb'

module ActiveGenie::EloRanking
  class Tournament
    def self.call(players, criteria, options: {})
      new(players, criteria, options:).call
    end

    def initialize(players, criteria, options: {})
      @players = players
      @criteria = criteria
      @options = options
    end

    def call
      # 1. generate initial ratings
      #   1.1 eliminate players with initial rating to low (low rating = 25% percentile if avg/STDEV pass 0.3)
      # 2. convert the ratings to Elo, separate the players into 2 tiers. On tier for elimination and other tier for defend. Both tiers has the same number of players.
      # 3. create round. Round is a collection of matches, each match is a pair of players
      #   3.1. focus on the players with the lowest rating.
      #   3.2. Each lowest rating player will battle 3 times against the next tier player.
      #   3.3. Each battle will update the elo of the players involved.
      # 4. take the players on the boundary of 2 tiers and battle them against each other.
      # 5. remove the last 30% lowest rating players from the tournament.
      # 6. repeat 3-4 until top10 is reached
      # 7. return the top 10 players

      # Notes
      # - challenger player that lose 2 battles don't need to battle anymore.
      # - defender player that lose will suffer great penalty like (-15 elo)  + elo score calculated
      # - Players with initial rating too low, is eliminated even before the rounds

      scored_players = @players.map { |player| { **player, score: score_for(player) } }
      @elo_players = ActiveGenie::EloRanking::PlayerCollection.build(scored_players)
      # @elo_players.eligible

      relegation_players = @elo_players.relegation_players
      defense_players = @elo_players.defense_players

      matches = []
      relegation_players.each do |player_a|
        matches << [player_a, defense_players.sample]
        matches << [player_a, defense_players.sample]
        matches << [player_a, defense_players.sample]
      end

      matches.each do |match|
        winner = Battle.call(
          match[0],
          match[1],
          @criteria,
          options: @options
        )[:winner_player]

        if winner == match[0]
          match[0].win!
          match[1].lose!
        elsif winner == match[1]
          match[0].lose!
          match[1].win!
        else
          match[0].draw!
          match[1].draw!
        end
      end

    end

    private


    def score_for(player)
      ActiveGenie::Scoring::Basic.call(
        player[:content],
        @criteria,
        reviewers_names,
        options: @options
      )[:final_score]
    end

    def reviewers_names
      [reviewers[:reviewer1], reviewers[:reviewer2], reviewers[:reviewer3]]
    end

    def reviewers
      @reviewers ||= ActiveGenie::Scoring::RecommendedReviews.call(
        @players.first,
        @criteria,
        options: @options
      )
    end
  end
end

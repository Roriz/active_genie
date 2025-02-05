require_relative '../battle/basic'

module ActiveGenie::Leaderboard
  class League
    def self.call(players, criteria, options: {})
      new(players, criteria, options:).call
    end

    def initialize(players, criteria, options: {})
      @players = players
      @criteria = criteria
      @options = options
    end

    def call
      matches.each do |player_a, player_b|
        winner, loser = battle(player_a, player_b)

        if winner.nil? || loser.nil?
          player_a.league[:draw] += 1
          player_b.league[:draw] += 1
        else
          winner.league[:win] += 1
          loser.league[:lose] += 1
        end
      end

      @players
    end

    private

    # TODO: reduce the number of matches based on transitivity.
    #       For example, if A is better than B, and B is better than C, then A should clearly be better than C
    def matches
      @players.eligible.combination(2).to_a
    end

    def battle(player_a, player_b)
      ActiveGenie::Battle.basic(
        player_a,
        player_b,
        @criteria,
        options: @options
      ).values_at('winner', 'loser')
    end
  end
end

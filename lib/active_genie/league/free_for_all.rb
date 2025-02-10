require_relative '../battle/basic'

module ActiveGenie::Leaderboard
  class FreeForAll
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
      matches.each do |player_a, player_b|
        winner, loser = battle(player_a, player_b)

        if winner.nil? || loser.nil?
          player_a.free_for_all[:draw] += 1
          player_b.free_for_all[:draw] += 1
        else
          winner.free_for_all[:win] += 1
          loser.free_for_all[:lose] += 1
        end

        ActiveGenie::Logger.trace({**log, step: :free_for_all_battle, winner_id: winner&.id, player_a_id: player_a.id, player_a_free_for_all_score: player_a.free_for_all_score, player_b_id: player_b.id, player_b_free_for_all_score: player_b.free_for_all_score })
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
      result = ActiveGenie::Battle.basic(
        player_a,
        player_b,
        @criteria,
        config:
      )


      result.values_at('winner', 'loser')
    end

    def config
      { **@config }
    end

    def log
      { **(@config.dig(:log) || {}), duration: Time.now - @start_time }
    end
  end
end

require_relative '../battle/basic'

module ActiveGenie::Ranking
  class FreeForAll
    def self.call(...)
      new(...).call
    end

    def initialize(players, criteria, config: {})
      @players = players
      @criteria = criteria
      @config = config
    end

    def call
      ActiveGenie::Logger.with_context(log_context) do
        matches.each do |player_a, player_b|
          winner, loser = battle(player_a, player_b)
          
          if winner.nil? || loser.nil?
            player_a.draw!
            player_b.draw!
          else
            winner.win!
            loser.lose!
          end
        end

        # TODO: add a freeForAll report. Duration, Elo changes, etc.
      end
    end

    private

    # TODO: reduce the number of matches based on transitivity.
    #       For example, if A is better than B, and B is better than C, then battle between A and C should be auto win A
    def matches
      @players.eligible.combination(2).to_a
    end

    def battle(player_a, player_b)
      result = ActiveGenie::Battle.basic(
        player_a,
        player_b,
        @criteria,
        config: @config
      )

      winner, loser = case result['winner']
        when 'player_a' then [player_a, player_b, result['reasoning']]
        when 'player_b' then [player_b, player_a, result['reasoning']]
        when 'draw' then [nil, nil, result['reasoning']]
      end

      ActiveGenie::Logger.debug({
        step: :free_for_all_battle,
        player_ids: [player_a.id, player_b.id],
        winner_id: winner&.id,
        loser_id: loser&.id,
        reasoning: result['reasoning']
      })

      [winner, loser]
    end

    def log_context
      { free_for_all_id: }
    end

    def free_for_all_id
      eligible_ids = @players.eligible.map(&:id).join(',')
      ranking_unique_key = [eligible_ids, @criteria, @config.to_json].join('-')
      Digest::MD5.hexdigest(ranking_unique_key)
    end
  end
end

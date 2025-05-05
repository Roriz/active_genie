# frozen_string_literal: true

require_relative '../battle/generalist'

module ActiveGenie
  module Ranking
    class FreeForAll
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, config: {})
        @players = players
        @criteria = criteria
        @config = config
        @start_time = Time.now
        @total_tokens = 0
      end

      def call
        ActiveGenie::Logger.with_context(log_context, observer: method(:log_observer)) do
          matches.each do |player_1, player_2|
            winner, loser = battle(player_1, player_2)

            if winner.nil? || loser.nil?
              player_1.draw!
              player_2.draw!
            else
              winner.win!
              loser.lose!
            end

            @config[:runtime][:watch_players]&.call(@players)
          end
        end

        ActiveGenie::Logger.info({ code: :free_for_all_report, **report })

        report
      end

      private

      # TODO: reduce the number of matches based on transitivity.
      #       For example, if A is better than B, and B is better than C, then battle between A and C should be auto win A
      def matches
        @players.eligible.combination(2).to_a
      end

      def battle(player_1, player_2)
        result = ActiveGenie::Battle.call(
          player_1.content,
          player_2.content,
          @criteria,
          config: @config
        )

        winner, loser = case result['winner']
                        when 'player_1' then [player_1, player_2, result['reasoning']]
                        when 'player_2' then [player_2, player_1, result['reasoning']]
                        when 'draw' then [nil, nil, result['reasoning']]
                        end

        @config[:runtime][:watch_battle]&.call({ id: "#{player_1.id}_#{player_2.id}_#{free_for_all_id}", player_1:,
                                                 player_2:, winner:, loser:, reasoning: result['reasoning'] })
        ActiveGenie::Logger.debug({
                                    code: :free_for_all_battle,
                                    player_ids: [player_1.id, player_2.id],
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

      def report
        {
          free_for_all_id:,
          battles_count: matches.size,
          duration_seconds: Time.now - @start_time,
          total_tokens: @total_tokens
        }
      end

      def log_observer(log)
        @total_tokens += log[:total_tokens] if log[:code] == :llm_usage
      end
    end
  end
end

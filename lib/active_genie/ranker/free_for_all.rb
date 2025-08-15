# frozen_string_literal: true

module ActiveGenie
  module Ranker
    class FreeForAll
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, config: nil)
        @players = Entities::Players.new(players)
        @criteria = criteria
        @config = config || ActiveGenie.configuration
        @start_time = Time.now
        @total_tokens = 0
      end

      def call
        @config.log.add_observer(observers: ->(log) { log_observer(log) })
        @config.log.additional_context = { free_for_all_id: }

        ActiveGenie::FiberByBatch.call(matches, config: @config) do |player_a, player_b|
          winner, loser = debate(player_a, player_b)

          update_players_score(winner, loser)
        end

        build_report
      end

      private

      # TODO: reduce the number of matches based on transitivity.
      #       For example, if A is better than B, and B is better than C, then debate between A and C should be auto win A
      def matches
        @players.eligible.combination(2).to_a
      end

      def debate(player_a, player_b)
        log_context = { player_a_id: player_a.id, player_b_id: player_b.id }

        result = ActiveGenie::Comparator.by_debate(
          player_a.content,
          player_b.content,
          @criteria,
          config: @config.merge(additional_context: log_context)
        )

        winner, loser = case result['winner']
                        when 'player_a' then [player_a, player_b]
                        when 'player_b' then [player_b, player_a]
                        when 'draw' then [nil, nil]
                        end

        @config.logger.call(
          {
            **log_context,
            code: :free_for_all,
            winner_id: winner&.id,
            loser_id: loser&.id,
            reasoning: result['reasoning']
          }
        )

        [winner, loser]
      end

      def update_players_score(winner, loser)
        return if winner.nil? || loser.nil?

        if winner.nil? || loser.nil?
          player_a.draw!
          player_b.draw!
        else
          winner.win!
          loser.lose!
        end
      end

      def free_for_all_id
        @free_for_all_id ||= begin
          eligible_ids = @players.eligible.map(&:id).join(',')
          ranking_unique_key = [eligible_ids, @criteria, @config.to_json].join('-')
          Digest::MD5.hexdigest(ranking_unique_key)
        end
      end

      def build_report
        report = {
          free_for_all_id:,
          debates_count: matches.size,
          duration_seconds: Time.now - @start_time,
          total_tokens: @total_tokens
        }

        @config.logger.call({ code: :free_for_all_report, **report })

        report
      end

      def log_observer(log)
        @total_tokens += log[:total_tokens] if log[:code] == :llm_usage
      end
    end
  end
end

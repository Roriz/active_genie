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
        @initial_config = config
        @start_time = Time.now
        @total_tokens = 0
      end

      def call
        ActiveGenie::FiberByBatch.call(matches, config:) do |player_a, player_b|
          winner, loser = debate(player_a, player_b)

          update_players_score(winner, loser)
        end

        build_result
      end

      private

      # TODO: reduce the number of matches based on transitivity.
      #       For example, if A is better than B, and B is better than C, then debate between A and C should be auto win A
      def matches
        @players.eligible.combination(2).to_a
      end

      def debate(player_a, player_b)
        debate_config = ActiveGenie::DeepMerge.call(
          config.to_h,
          { log: { additional_context: { player_a_id: player_a.id, player_b_id: player_b.id } } }
        )

        result = ActiveGenie::Comparator.by_debate(
          player_a.content,
          player_b.content,
          @criteria,
          config: ActiveGenie.new_configuration(debate_config)
        )

        winner, loser = case result.data
                        when player_a.to_s then [player_a, player_b]
                        else [player_b, player_a]
                        end

        ActiveGenie.logger.call(
          {
            player_a_id: player_a.id,
            player_b_id: player_b.id,
            code: :free_for_all,
            winner: winner.to_s[0..20],
            loser: loser.to_s[0..20],
            reasoning: result.reasoning
          }, config:
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
          ranking_unique_key = [eligible_ids, @criteria].join('-')
          Digest::MD5.hexdigest(ranking_unique_key)
        end
      end

      def build_result
        result = ActiveGenie::Result.new(
          data: @players.sorted.map(&:content),
          metadata: {
            free_for_all_id:,
            players: @players,
            debates_count: matches.size,
            duration_seconds: Time.now - @start_time,
            total_tokens: @total_tokens
          }
        )

        ActiveGenie.logger.call({ code: :free_for_all_report, **result.metadata }, config:)

        result
      end

      def log_observer(log)
        @total_tokens += log[:total_tokens] if log[:code] == :llm_usage
      end

      def config
        @config ||= begin
          c = ActiveGenie.new_configuration(
            ActiveGenie::DeepMerge.call(
              @initial_config.to_h,
              { log: { context: { free_for_all_id: } } }
            )
          )
          c.log.add_observer(observers: ->(log) { log_observer(log) })
          c
        end
      end
    end
  end
end

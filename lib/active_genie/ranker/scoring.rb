# frozen_string_literal: true

require_relative '../utils/fiber_by_batch'

module ActiveGenie
  module Ranker
    class Scoring
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, juries: [], config: nil)
        @players = Values::Players.new(players)
        @criteria = criteria
        @initial_config = config
        @juries = Array(juries).compact.uniq
      end

      def call
        unless players_without_score.empty?
          # Resolved once, before scoring fans out concurrently.
          juries = shared_juries
          ActiveGenie::FiberByBatch.call(players_without_score, config:) do |player|
            player.score = generate_score(player, juries)
          end
        end

        ActiveGenie::Result.new(
          data: @players.sorted.map(&:content),
          reasoning: nil,
          metadata: @players.map(&:to_h)
        )
      end

      private

      def players_without_score
        @players_without_score ||= @players.select { |player| player.score.nil? }
      end

      def generate_score(player, juries)
        result = ActiveGenie::Scorer.by_jury_bench(
          player.content,
          @criteria,
          juries,
          config:
        )
        score = result.data.to_i
        reasoning = result.reasoning

        ActiveGenie.logger.call({ code: :new_score, player_id: player.id, score:, reasoning: }, config:)

        score
      end

      # Scores are only comparable if every player faces the same jury. When none
      # are given, list them once from the first players to be scored, rather
      # than letting the Scorer pick a different jury for each player.
      def shared_juries
        return @juries if @juries.any?

        sample = players_without_score.first(2).join("\n\n")
        juries = ActiveGenie::Lister::Juries.call(sample, @criteria, config:).data
        ActiveGenie.logger.call({ code: :new_juries, juries: }, config:)
        juries
      end

      def ranker_scoring_id
        @ranker_scoring_id ||= begin
          player_ids = players_without_score.map(&:id).join(',')
          ranker_unique_key = [player_ids, @criteria].join('-')

          "#{Digest::MD5.hexdigest(ranker_unique_key)}-scoring"
        end
      end

      def config
        @config ||= ActiveGenie.new_configuration(
          DeepMerge.call(
            @initial_config,
            { log: { additional_context: { ranker_scoring_id: } } }
          )
        )
      end
    end
  end
end

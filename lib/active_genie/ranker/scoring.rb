# frozen_string_literal: true

require_relative '../utils/fiber_by_batch'

module ActiveGenie
  module Ranker
    class Scoring
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, juries: [], config: nil)
        @players = Entities::Players.new(players)
        @criteria = criteria
        @initial_config = config
        @juries = Array(juries).compact.uniq
      end

      def call
        ActiveGenie::FiberByBatch.call(players_without_score, config:) do |player|
          player.score = generate_score(player)
        end
      end

      private

      def players_without_score
        @players_without_score ||= @players.select { |player| player.score.nil? }
      end

      def generate_score(player)
        score, reasoning = ActiveGenie::Scorer.by_jury_bench(
          player.content,
          @criteria,
          @juries,
          config:
        ).values_at('final_score', 'final_reasoning')

        ActiveGenie.logger.call({ code: :new_score, player_id: player.id, score:, reasoning: }, config:)

        score
      end

      def juries
        @juries ||= begin
          response = ActiveGenie::Lister.juries(
            [@players.sample.content, @players.sample.content].join("\n\n"),
            @criteria,
            config:
          )
          ActiveGenie.logger.call({ code: :new_juries, juries: response }, config:)
          response
        end
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

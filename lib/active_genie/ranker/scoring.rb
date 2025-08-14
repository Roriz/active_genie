# frozen_string_literal: true

module ActiveGenie
  module Ranker
    class Scoring
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, juries: [], config: nil)
        @players = Players.new(players)
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
        @juries = Array(juries).compact.uniq
      end

      def call
        @config.log.additional_context = { ranker_scoring_id: }

        players_without_score.each do |player|
          player.score = generate_score(player)
        end
      end

      private

      def players_without_score
        @players_without_score ||= @players.select { |player| player.score.nil? }
      end

      def generate_score(player)
        score, reasoning = ActiveGenie::Scorer.jury_bench(
          player.content,
          @criteria,
          @juries,
          config: @config
        ).values_at('final_score', 'final_reasoning')

        @config.logger.call({ code: :new_score, player_id: player.id, score:, reasoning: })

        score
      end

      def juries
        @juries ||= begin
          response = ActiveGenie::Lister.juries(
            [@players.sample.content, @players.sample.content].join("\n\n"),
            @criteria,
            config: @config
          )
          @config.logger.call({ code: :new_juries, juries: response })
          response
        end
      end

      def ranker_scoring_id
        @ranker_scoring_id ||= begin
          player_ids = players_without_score.map(&:id).join(',')
          ranker_unique_key = [player_ids, @criteria, @config.to_json].join('-')

          "#{Digest::MD5.hexdigest(ranker_unique_key)}-scoring"
        end
      end
    end
  end
end

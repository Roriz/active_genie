# frozen_string_literal: true

require_relative '../scoring/recommended_reviewers'

module ActiveGenie
  module Ranking
    class RankingScoring
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, reviewers: [], config: {})
        @players = players
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
        @reviewers = Array(reviewers).compact.uniq
      end

      def call
        @reviewers = generate_reviewers

        players_without_score.each do |player|
          player.score = generate_score(player)
        end
      end

      private

      def players_without_score
        @players_without_score ||= @players.select { |player| player.score.nil? }
      end

      def generate_score(player)
        score, reasoning = ActiveGenie::Scoring.call(
          player.content,
          @criteria,
          @reviewers,
          config: @config.merge(
            additional_context: { ranking_scoring_id: }
          )
        ).values_at('final_score', 'final_reasoning')

        @config.logger.call({ ranking_scoring_id:, code: :new_score, player_id: player.id, score:, reasoning: })

        score
      end

      def generate_reviewers
        return @reviewers if @reviewers.size.positive?

        reviewer1, reviewer2, reviewer3 = ActiveGenie::Scoring::RecommendedReviewers.call(
          [@players.sample.content, @players.sample.content].join("\n\n"),
          @criteria,
          config: @config.merge(
            additional_context: { ranking_scoring_id: }
          )
        ).values_at('reviewer1', 'reviewer2', 'reviewer3')

        @config.logger.call({ ranking_scoring_id:, code: :new_reviewers, reviewers: [reviewer1, reviewer2, reviewer3] })

        [reviewer1, reviewer2, reviewer3]
      end

      def ranking_scoring_id
        @ranking_scoring_id ||= begin
          player_ids = players_without_score.map(&:id).join(',')
          ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

          "#{Digest::MD5.hexdigest(ranking_unique_key)}-scoring"
        end
      end
    end
  end
end

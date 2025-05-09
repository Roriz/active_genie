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
        @config = ActiveGenie::Configuration.to_h(config)
        @reviewers = Array(reviewers).compact.uniq
      end

      def call
        ActiveGenie::Logger.with_context(log_context) do
          @reviewers = generate_reviewers

          players_to_score = players_without_score
          until players_to_score.empty?
            threads = []
            mutex = Mutex.new

            # Take up to 3 players for parallel processing
            current_batch = players_to_score.shift(3)

            current_batch.each do |player|
              threads << Thread.new(player) do |p|
                score = generate_score(p)

                mutex.synchronize do
                  p.score = score
                end
              end
            end

            # Wait for all threads in this batch to complete
            threads.each(&:join)
          end
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
          config: @config
        ).values_at('final_score', 'final_reasoning')

        ActiveGenie::Logger.debug({ code: :new_score, player_id: player.id, score:, reasoning: })
        @config[:runtime][:watch_scoring]&.call({
                                                  player_id: player.id,
                                                  player_name: player.content[0..10],
                                                  score: player.score
                                                })

        score
      end

      def generate_reviewers
        return @reviewers if @reviewers.size.positive?

        reviewer1, reviewer2, reviewer3 = ActiveGenie::Scoring::RecommendedReviewers.call(
          [@players.sample.content, @players.sample.content].join("\n\n"),
          @criteria,
          config: @config
        ).values_at('reviewer1', 'reviewer2', 'reviewer3')

        ActiveGenie::Logger.debug({ code: :new_reviewers, reviewers: [reviewer1, reviewer2, reviewer3] })

        [reviewer1, reviewer2, reviewer3]
      end

      def log_context
        { ranking_scoring_id: }
      end

      def ranking_scoring_id
        player_ids = players_without_score.map(&:id).join(',')
        ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

        "#{Digest::MD5.hexdigest(ranking_unique_key)}-scoring"
      end
    end
  end
end

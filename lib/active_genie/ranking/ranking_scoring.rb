require_relative '../scoring/recommended_reviewers'

module ActiveGenie::Ranking
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

        players_without_score.each do |player|
          # TODO: This can take a while, can be parallelized
          player.score = generate_score(player)
        end
      end
    end

    private

    def players_without_score
      @players_without_score ||= @players.select { |player| player.score.nil? }
    end

    def generate_score(player)
      score, reasoning = ActiveGenie::Scoring::Basic.call(
        player.content,
        @criteria,
        @reviewers,
        config: @config
      ).values_at('final_score', 'final_reasoning')

      ActiveGenie::Logger.debug({step: :new_score, player_id: player.id, score:, reasoning: })

      score
    end

    def generate_reviewers
      return @reviewers if @reviewers.size > 0

      reviewer1, reviewer2, reviewer3 = ActiveGenie::Scoring::RecommendedReviewers.call(
        [@players.sample.content, @players.sample.content].join("\n\n"),
        @criteria,
        config: @config
      ).values_at('reviewer1', 'reviewer2', 'reviewer3')
      
      ActiveGenie::Logger.debug({step: :new_reviewers, reviewers: [reviewer1, reviewer2, reviewer3] })

      [reviewer1, reviewer2, reviewer3]
    end

    def log_context
      { ranking_scoring_id: }
    end

    def ranking_scoring_id
      player_ids = players_without_score.map(&:id).join(',')
      ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

      Digest::MD5.hexdigest(ranking_unique_key)
    end
  end
end

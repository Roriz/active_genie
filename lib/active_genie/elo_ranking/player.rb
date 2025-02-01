require 'securerandom'
require_relative '../scoring/basic'

module ActiveGenie::EloRanking
  class Player
    def initialize(params)
      params = { content: params } if params.is_a?(String)

      @id = params.dig(:id) || SecureRandom.uuid
      @content = params.dig(:content) || params
      @score = params.dig(:score) || nil
      @elo = params.dig(:elo) || nil
      @eliminated = params.dig(:eliminated) || false
    end

    attr_reader :id, :content, :score, :elo, :eliminated
    attr_writer :elo

    def generate_score(criteria, reviewers, options:)
      return if !@score.nil?

      @score = ActiveGenie::Scoring::Basic.call(
        @content,
        criteria,
        reviewers,
        options:
      )['final_score']
    end

    def generate_elo(base)
      return if !@elo.nil?

      @elo = base + (@score - 50)
    end

    def eliminate!
      @eliminated = true
    end

    def to_h
      { id:, content:, score:, elo:, eliminated: }
    end
  end
end
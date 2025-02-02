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

    def generate_elo_by_score
      return if !@elo.nil? || @score.nil?

      @elo = BASE_ELO + (@score - 50)
    end

    def eliminate!
      @eliminated = true
    end

    def score=(value)
      @score = value
    end

    def elo=(value)
      @elo = value
    end

    def to_h
      { id:, content:, score:, elo:, eliminated: }
    end

    private
    
    BASE_ELO = 1000
  end
end
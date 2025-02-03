require 'securerandom'

module ActiveGenie::Leaderboard
  class Player
    def initialize(params)
      params = { content: params } if params.is_a?(String)

      @id = params.dig(:id) || SecureRandom.uuid
      @content = params.dig(:content) || params
      @score = params.dig(:score) || nil
      @elo = params.dig(:elo) || nil
      @league = {
        win: params.dig(:league, :win) || 0,
        lose: params.dig(:league, :lose) || 0,
        draw: params.dig(:league, :draw) || 0
      }
      @eliminated = params.dig(:eliminated) || nil
    end

    attr_reader :id, :content, :score, :elo, :league, :eliminated

    def generate_elo_by_score
      return if !@elo.nil? || @score.nil?

      @elo = BASE_ELO + (@score - 50)
    end

    def score=(value)
      @score = value
    end

    def elo=(value)
      @elo = value
    end

    def eliminated=(value)
      @eliminated = value
    end

    def league_score
      @league[:win] * 3 + @league[:draw]
    end

    def to_h
      { id:, content:, score:, elo:, eliminated:, league: }
    end

    private
    
    BASE_ELO = 1000
  end
end
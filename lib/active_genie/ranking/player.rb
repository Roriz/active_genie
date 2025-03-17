require 'securerandom'

module ActiveGenie::Ranking
  class Player
    def initialize(params)
      params = { content: params } if params.is_a?(String)

      @id = params.dig(:id) || SecureRandom.uuid
      @content = params.dig(:content) || params
      @score = params.dig(:score) || nil
      @elo = params.dig(:elo) || nil
      @free_for_all = {
        win: params.dig(:free_for_all, :win) || 0,
        lose: params.dig(:free_for_all, :lose) || 0,
        draw: params.dig(:free_for_all, :draw) || 0
      }
      @eliminated = params.dig(:eliminated) || nil
    end

    attr_reader :id, :content, :score, :elo, :free_for_all, :eliminated
    attr_accessor :rank

    def generate_elo_by_score
      return if !@elo.nil?

      if @score.nil?
        @elo = BASE_ELO
      else
        @elo = BASE_ELO + (@score - 50)
      end
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

    def free_for_all_score
      @free_for_all[:win] * 3 + @free_for_all[:draw]
    end

    def to_h(rank:)
      {
        id:, content:, score:, elo:,
        eliminated:, free_for_all:, free_for_all_score:, rank:
      }
    end

    private
    
    BASE_ELO = 1000
  end
end
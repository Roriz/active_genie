require 'digest'

module ActiveGenie::Ranking
  class Player
    def initialize(params)
      params = { content: params } if params.is_a?(String)

      @content = params.dig(:content) || params
      @id = params.dig(:id) || Digest::MD5.hexdigest(@content)
      @score = params.dig(:score) || nil
      @elo = params.dig(:elo) || nil
      @ffa_win_count = params.dig(:ffa_win_count) || 0
      @ffa_lose_count = params.dig(:ffa_lose_count) || 0
      @ffa_draw_count = params.dig(:ffa_draw_count) || 0
      @eliminated = params.dig(:eliminated) || nil
    end

    attr_reader :id, :content, :score, :elo, 
      :ffa_win_count, :ffa_lose_count, :ffa_draw_count,
      :eliminated
    attr_accessor :rank

    def score=(value)
      @score = value
    end

    def elo
      generate_elo_by_score if @elo.nil?

      @elo
    end

    def elo=(value)
      @elo = value
      ActiveGenie::Logger.debug({ step: :new_elo, player_id: id, elo: value })
    end

    def eliminated=(value)
      @eliminated = value
      ActiveGenie::Logger.debug({ step: :new_eliminated, player_id: id, eliminated: value })
    end

    def draw!
      @ffa_draw_count += 1
      ActiveGenie::Logger.debug({ step: :new_ffa_score, player_id: id, result: 'draw', ffa_score: })
    end

    def win!
      @ffa_win_count += 1
      ActiveGenie::Logger.debug({ step: :new_ffa_score, player_id: id, result: 'win', ffa_score: })
    end

    def lose!
      @ffa_lose_count += 1
      ActiveGenie::Logger.debug({ step: :new_ffa_score, player_id: id, result: 'lose', ffa_score: })
    end

    def ffa_score
      @ffa_win_count * 3 + @ffa_draw_count
    end

    def to_h
      {
        id:, content:, score:, elo:,
        ffa_win_count:, ffa_lose_count:, ffa_draw_count:,
        eliminated:, ffa_score:
      }
    end

    def method_missing(method_name, *args, &block)
      if method_name == :[] && args.size == 1
        attr_name = args.first.to_sym

        if respond_to?(attr_name) 
          return send(attr_name)
        else
          return nil
        end
      end

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name == :[] || super
    end

    private
    
    BASE_ELO = 1000

    def generate_elo_by_score
      @elo = BASE_ELO + ((@score || 0) - 50)
    end
  end
end
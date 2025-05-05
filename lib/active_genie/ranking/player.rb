# frozen_string_literal: true

require 'digest'

module ActiveGenie
  module Ranking
    class Player
      def initialize(params)
        params = { content: params } if params.is_a?(String)

        @content = params[:content] || params
        @name = params[:name] || params[:content][0..10]
        @id = params[:id] || Digest::MD5.hexdigest(@content)
        @score = params[:score] || nil
        @elo = params[:elo] || nil
        @ffa_win_count = params[:ffa_win_count] || 0
        @ffa_lose_count = params[:ffa_lose_count] || 0
        @ffa_draw_count = params[:ffa_draw_count] || 0
        @eliminated = params[:eliminated] || nil
      end
      attr_accessor :rank

      def score=(value)
        ActiveGenie::Logger.debug({ code: :new_score, player_id: id, score: value }) if value != @score
        @score = value
        @elo = generate_elo_by_score
      end

      def elo=(value)
        ActiveGenie::Logger.debug({ code: :new_elo, player_id: id, elo: value }) if value != @elo
        @elo = value
      end

      def eliminated=(value)
        ActiveGenie::Logger.debug({ code: :new_eliminated, player_id: id, eliminated: value }) if value != @eliminated
        @eliminated = value
      end

      def draw!
        @ffa_draw_count += 1
        ActiveGenie::Logger.debug({ code: :new_ffa_score, player_id: id, result: 'draw', ffa_score: })
      end

      def win!
        @ffa_win_count += 1
        ActiveGenie::Logger.debug({ code: :new_ffa_score, player_id: id, result: 'win', ffa_score: })
      end

      def lose!
        @ffa_lose_count += 1
        ActiveGenie::Logger.debug({ code: :new_ffa_score, player_id: id, result: 'lose', ffa_score: })
      end

      attr_reader :id, :content, :score, :elo, :ffa_win_count, :ffa_lose_count, :ffa_draw_count, :eliminated, :name

      def ffa_score
        @ffa_win_count * 3 + @ffa_draw_count
      end

      def sort_value
        (ffa_score * 1_000_000) + ((elo || 0) * 100) + (score || 0)
      end

      def to_json(*_args)
        to_h.to_json
      end

      def to_h
        {
          id:, name:, content:, score:, elo:,
          ffa_win_count:, ffa_lose_count:, ffa_draw_count:,
          eliminated:, ffa_score:, sort_value:
        }
      end

      def method_missing(method_name, *args, &block)
        if method_name == :[] && args.size == 1
          attr_name = args.first.to_sym

          return send(attr_name) if respond_to?(attr_name)

          return nil

        end

        super
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name == :[] || super
      end

      def generate_elo_by_score
        BASE_ELO + ((@score || 0) - 50)
      end

      BASE_ELO = 1000
    end
  end
end

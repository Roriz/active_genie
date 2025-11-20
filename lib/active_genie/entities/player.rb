# frozen_string_literal: true

require 'digest'

module ActiveGenie
  module Ranker
    module Entities
      class Player
        def initialize(params)
          @params = params.is_a?(String) ? { content: params } : params.dup
          @params[:content] ||= @params
        end

        def content
          @content ||= @params[:content]
        end

        def name
          @name ||= @params[:name] || content[0..10]
        end

        def id
          @id ||= @params[:id] || Digest::MD5.hexdigest(content.to_s)
        end

        def score
          @score ||= @params[:score]
        end

        def elo
          @elo = @elo || @params[:elo] || generate_elo_by_score
        end

        def ffa_win_count
          @ffa_win_count ||= @params[:ffa_win_count] || 0
        end

        def ffa_lose_count
          @ffa_lose_count ||= @params[:ffa_lose_count] || 0
        end

        def ffa_draw_count
          @ffa_draw_count ||= @params[:ffa_draw_count] || 0
        end

        def eliminated
          @eliminated ||= @params[:eliminated]
        end

        def score=(value)
          @score = value
          @elo = generate_elo_by_score
        end

        def elo=(value)
          @elo = value || BASE_ELO
        end

        attr_writer :eliminated

        def draw!
          @ffa_draw_count = ffa_draw_count + 1
        end

        def win!
          @ffa_win_count = ffa_win_count + 1
        end

        def lose!
          @ffa_lose_count = ffa_lose_count + 1
        end

        def ffa_score
          (ffa_win_count * 3) + ffa_draw_count
        end

        def sort_value
          (ffa_score * 1_000_000) + ((elo || 0) * 100) + (score || 0)
        end

        def to_json(*_args)
          to_h.to_json
        end

        def to_h
          {
            id:, name:, content:,

            score:, elo:,
            ffa_win_count:, ffa_lose_count:, ffa_draw_count:,
            eliminated:, ffa_score:, sort_value:
          }
        end

        def to_s
          content.to_s
        end

        def method_missing(method_name, *args, &)
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

        BASE_ELO = 1000

        private

        def generate_elo_by_score
          return BASE_ELO if @score.nil?

          BASE_ELO + (@score - 50)
        end
      end
    end
  end
end

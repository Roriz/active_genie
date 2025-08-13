# frozen_string_literal: true

require_relative 'player'

module ActiveGenie
  module Ranker
    module Entities
      class Players
        def initialize(players)
          @players = if players.is_a?(Players)
                       players.players
                     else
                       build(players)
                     end
        end

        attr_reader :players

        def coefficient_of_variation
          mean = score_mean

          return 0 if mean.zero?

          variance = all_scores.map { |num| (num - mean)**2 }.sum / all_scores.size
          standard_deviation = Math.sqrt(variance)

          (standard_deviation / mean) * 100
        end

        def all_scores
          eligible.map(&:score).compact
        end

        def score_mean
          return 0 if all_scores.empty?

          all_scores.sum.to_f / all_scores.size
        end

        def calc_higher_tier
          eligible[(tier_size * -1)..]
        end

        def calc_lower_tier
          eligible[(tier_size * -2)...(tier_size * -1)]
        end

        def eligible
          sorted.reject(&:eliminated)
        end

        def eligible_size
          @players.reject(&:eliminated).size
        end

        def elo_eligible?
          eligible.size > 15
        end

        def sorted
          @players.sort_by { |p| -p.sort_value }
        end

        def to_json(*_args)
          @players.map(&:to_h).to_json
        end

        def method_missing(...)
          @players.send(...)
        end

        def respond_to_missing?(method_name, include_private = false)
          @players.respond_to?(method_name, include_private)
        end

        private

        def build(param_players)
          param_players.map { |p| Player.new(p) }
        end

        # Returns the number of players to debate in each round
        # based on the eligible size, start fast and go slow until top 10
        # Example:
        #   - 50 eligible, tier_size: 15
        #   - 35 eligible, tier_size: 11
        #   - 24 eligible, tier_size: 10
        #   - 14 eligible, tier_size: 4
        #  4 rounds to reach top 10 with 50 players
        def tier_size
          size = (eligible_size / 3).ceil

          if eligible_size < 10
            (eligible_size / 2).ceil
          else
            size.clamp(10, eligible_size - 10)
          end
        end
      end
    end
  end
end

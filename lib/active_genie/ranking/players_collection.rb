# frozen_string_literal: true

require_relative './player'

module ActiveGenie
  module Ranking
    class PlayersCollection
      def initialize(param_players)
        @players = build(param_players)
      end
      attr_reader :players

      def coefficient_of_variation
        score_list = eligible.map(&:score).compact
        return nil if score_list.empty?

        mean = score_list.sum.to_f / score_list.size
        return nil if mean.zero?

        variance = score_list.map { |num| (num - mean)**2 }.sum / score_list.size
        standard_deviation = Math.sqrt(variance)

        (standard_deviation / mean) * 100
      end

      def calc_relegation_tier
        eligible[(tier_size * -1)..]
      end

      def calc_defender_tier
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
        sorted_players = @players.sort_by { |p| -p.sort_value }
        sorted_players.each_with_index { |p, i| p.rank = i + 1 }
        sorted_players
      end

      def to_json(*_args)
        to_h.to_json
      end

      def to_h
        sorted.map(&:to_h)
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

      # Returns the number of players to battle in each round
      # based on the eligible size, start fast and go slow until top 10
      # Example:
      #   - 50 eligible, tier_size: 15
      #   - 35 eligible, tier_size: 11
      #   - 24 eligible, tier_size: 10
      #   - 14 eligible, tier_size: 4
      #  4 rounds to reach top 10 with 50 players
      def tier_size
        [[(eligible_size / 3).ceil, 10].max, eligible_size - 10].min
      end
    end
  end
end

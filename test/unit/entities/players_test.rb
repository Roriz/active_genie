# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Ranker
    module Entities
      class PlayersTest < Minitest::Test
        def test_tier_calculations_with_correct_indexing
          # Create 20 players with descending sort values (via scores)
          # player_0 has highest score (best), player_19 has lowest (worst)
          players_data = (0..19).map do |i|
            { id: "player_#{i}", content: "Player #{i}", score: 100 - i }
          end

          players = Players.new(players_data)

          # Verify sorting order (best player first)
          sorted = players.sorted
          assert_equal "player_0", sorted.first.id
          assert_equal "player_19", sorted.last.id

          # tier_size for 20 players:
          # size = (20 / 3).ceil = 7. clamped with (10..10) => 10.
          # lower_tier should be the last 10 players (the worst performing ones)
          lower_tier = players.calc_lower_tier
          assert_equal 10, lower_tier.size
          # should contain players 10 to 19
          assert_equal "player_10", lower_tier.first.id
          assert_equal "player_19", lower_tier.last.id

          # higher_tier should be the next 10 players above them (players 0 to 9)
          higher_tier = players.calc_higher_tier
          assert_equal 10, higher_tier.size
          assert_equal "player_0", higher_tier.first.id
          assert_equal "player_9", higher_tier.last.id
        end

        def test_sorted_deterministic_tie_breaker
          # Create players with identical scores/sort values but different IDs
          players_data = [
            { id: "player_c", content: "Player C", score: 50 },
            { id: "player_a", content: "Player A", score: 50 },
            { id: "player_b", content: "Player B", score: 50 }
          ]

          players = Players.new(players_data)
          sorted = players.sorted

          assert_equal %w[player_a player_b player_c], sorted.map(&:id)
        end
      end
    end
  end
end

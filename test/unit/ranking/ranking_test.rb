# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranking
    class RankingTest < Minitest::Test
      def setup
        @criteria = 'test criteria'
        @players = ActiveGenie::Ranking::PlayersCollection.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )
      end

      def test_with_a_small_number_of_players
        RankingScoring.stub(:call, nil) do
          FreeForAll.stub(:call, nil) do
            results = Ranking.call(@players, @criteria)
            assert_equal 2, results.size
          end
        end
      end

      def test_with_a_large_number_of_players
        players = PlayersCollection.new(
          (1..20).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )
        RankingScoring.stub(:call, nil) do
          EloRound.stub(:call, { highest_elo_diff: 0, players_in_round: [] }) do
            FreeForAll.stub(:call, nil) do
              results = Ranking.call(players, @criteria)
              assert_equal 20, results.size
            end
          end
        end
      end

      def test_with_elimination_due_to_high_score_variation
        players = PlayersCollection.new(
          (1..20).map { |i| { id: "player_#{i}", content: "Player #{i} content", score: i * 10 } }
        )
        ActiveGenie.configuration.ranking.score_variation_threshold = 10

        RankingScoring.stub(:call, nil) do
          EloRound.stub(:call, { highest_elo_diff: 0, players_in_round: [] }) do
            FreeForAll.stub(:call, nil) do
              results = Ranking.call(players, @criteria)
              assert_equal 11, results.select { |p| p[:eliminated].nil? }.size
            end
          end
        end
      end
    end
  end
end

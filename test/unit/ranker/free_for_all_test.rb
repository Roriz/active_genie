# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranker
    class FreeForAllTest < Minitest::Test
      def setup
        # always return the first player as winner
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
        )
      end

      # Critical Path: Result Interface
      def test_returns_result_with_sorted_players_as_data
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', ffa_win_count: 0 },
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0 }
          ]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_instance_of Array, result.data
        assert_equal 2, result.data.size
        assert_equal 'Player A content', result.data.first # winner (stub returns first player)
      end

      def test_returns_result_with_required_metadata
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert result.metadata[:free_for_all_id].is_a?(String)
        assert result.metadata[:players].is_a?(ActiveGenie::Ranker::Entities::Players)
        assert_equal 1, result.metadata[:debates_count]
        assert result.metadata[:duration_seconds].is_a?(Float)
        assert result.metadata[:total_tokens].is_a?(Integer)
      end

      # Critical Path: Ranking Logic
      def test_ranks_players_by_ffa_score
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', ffa_win_count: 2 },
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0 }
          ]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # player_a has 2 wins (6 points) + 1 win from debate = 3 wins (9 points)
        # player_b has 0 wins + 1 loss = 0 points
        assert_equal 'Player A content', result.data.first
        assert_equal 'Player B content', result.data.last
      end

      def test_updates_player_win_and_lose_counts
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', ffa_win_count: 0, ffa_lose_count: 0 },
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0, ffa_lose_count: 0 }
          ]
        )

        FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        winner = players.find { |p| p.id == 'player_a' }
        loser = players.find { |p| p.id == 'player_b' }

        assert_equal 1, winner.ffa_win_count
        assert_equal 0, winner.ffa_lose_count
        assert_equal 0, loser.ffa_win_count
        assert_equal 1, loser.ffa_lose_count
      end

      # Critical Path: Match Generation
      def test_creates_correct_number_of_matches
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..5).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # C(5,2) = 10 matches
        assert_equal 10, result.metadata[:debates_count]
      end

      def test_creates_all_unique_pairwise_combinations
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..4).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )

        ffa_instance = FreeForAll.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        ffa_instance.call

        matches = ffa_instance.send(:matches).map { |player_a, player_b| [player_a.id, player_b.id].sort }

        # C(4,2) = 6 unique matches
        assert_equal 6, matches.size
        assert_equal matches.uniq.size, matches.size

        expected_matches = [
          %w[player_1 player_2],
          %w[player_1 player_3],
          %w[player_1 player_4],
          %w[player_2 player_3],
          %w[player_2 player_4],
          %w[player_3 player_4]
        ].map(&:sort)

        assert_equal expected_matches.sort, matches.sort
      end

      # Critical Path: Edge Cases
      def test_handles_two_players_minimum
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 1, result.metadata[:debates_count]
        assert_equal 2, result.data.size
      end

      def test_all_players_participate_in_battles
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..10).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )

        FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        players.each do |player|
          total_battles = player.ffa_win_count + player.ffa_lose_count + player.ffa_draw_count
          assert total_battles > 0, "Player #{player.id} should have participated in battles"
        end
      end

      def test_accepts_players_as_array_of_hashes
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 2, result.data.size
      end

      def test_accepts_players_instance
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 2, result.data.size
      end
    end
  end
end

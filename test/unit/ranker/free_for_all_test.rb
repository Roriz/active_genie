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

      def test_free_for_all_ranking_return_correct_order
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', ffa_win_count: 2 }, # winner
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0 } # loser
          ]
        )
        criteria = 'test criteria'

        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 'Player A content', players.sorted.first.content
        assert_equal 'Player B content', players.sorted.last.content

        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0 }, # winner (because stub returns first player)
            { id: 'player_a', content: 'Player A content', ffa_win_count: 2 } # loser
          ]
        )
        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        # After one debate, player_b should have 1 win, player_a should still have 2 wins + 1 loss
        # player_a still has higher ffa_score (6 vs 3)
        assert_equal 'Player A content', players.sorted.first.content
        assert_equal 'Player B content', players.sorted.last.content
      end

      def test_free_for_all_updates_player_scores_correctly
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', ffa_win_count: 0, ffa_lose_count: 0 },
            { id: 'player_b', content: 'Player B content', ffa_win_count: 0, ffa_lose_count: 0 }
          ]
        )
        criteria = 'test criteria'

        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        winner = players.find { |p| p.id == 'player_a' }
        loser = players.find { |p| p.id == 'player_b' }

        assert_equal 1, winner.ffa_win_count
        assert_equal 0, winner.ffa_lose_count
        assert_equal 3, winner.ffa_score # 1 win * 3 points

        assert_equal 0, loser.ffa_win_count
        assert_equal 1, loser.ffa_lose_count
        assert_equal 0, loser.ffa_score # 0 wins
      end

      def test_amount_of_matches
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..5).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )
        criteria = 'test criteria'

        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        # Free-for-all should have n * (n-1) / 2 matches (all combinations)
        expected_matches = (5 * 4) / 2
        assert_equal expected_matches, result[:debates_count]
      end

      def test_matches_are_all_unique_combinations
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..4).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )
        criteria = 'test criteria'

        ffa_instance = FreeForAll.new(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })
        ffa_instance.call

        matches = ffa_instance.send(:matches).map { |player_a, player_b| [player_a.id, player_b.id].sort }

        # Should have 6 unique matches for 4 players: C(4,2) = 6
        assert_equal 6, matches.count
        assert_equal matches.uniq.count, matches.count, 'All matches should be unique'

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

      def test_free_for_all_with_larger_player_set
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..10).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )
        criteria = 'test criteria'

        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        # C(10,2) = 45 matches
        expected_matches = (10 * 9) / 2
        assert_equal expected_matches, result[:debates_count]

        # Verify all players have participated in battles
        players.each do |player|
          total_battles = player.ffa_win_count + player.ffa_lose_count + player.ffa_draw_count
          assert total_battles > 0, "Player #{player.id} should have participated in at least one battle"
        end
      end

      def test_free_for_all_report_includes_metadata
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..3).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )
        criteria = 'test criteria'

        result = FreeForAll.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert result[:free_for_all_id].is_a?(String), 'Should have a free_for_all_id'
        assert result[:debates_count].is_a?(Integer), 'Should have debates_count'
        assert result[:duration_seconds].is_a?(Float), 'Should have duration_seconds'
        assert result[:total_tokens].is_a?(Integer), 'Should have total_tokens'
      end
    end
  end
end

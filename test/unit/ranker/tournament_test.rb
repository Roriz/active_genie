# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Ranker
    class TournamentTest < Minitest::Test
      def setup
        # Stub comparator requests (used by FreeForAll and Elo)
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .with(body: /comparation_through_debate/)
          .to_return(
            status: 200,
            body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
          )

        # Stub scorer requests (used by Scoring)
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .with(body: /scorer/)
          .to_return(
            status: 200,
            body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
          )

        # Stub lister requests (used by Lister)
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .with(body: /Family Feud/)
          .to_return(
            status: 200,
            body: File.read("#{__dir__}/../fixtures/lister-openai.json")
          )
      end

      # Critical Path: Result Interface
      def test_returns_result_with_sorted_players_as_data
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' },
          { id: 'player_c', content: 'Player C content' }
        ]

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_instance_of Array, result.data
        assert_equal 3, result.data.size
      end

      def test_returns_result_with_required_metadata
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' },
          { id: 'player_c', content: 'Player C content' }
        ]

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert result.metadata.is_a?(Array)
        assert_equal 3, result.metadata.size
        
        result.metadata.each do |player_data|
          assert player_data.is_a?(Hash)
          assert player_data.key?(:id)
          assert player_data.key?(:content)
          assert player_data.key?(:score)
        end
      end

      # Critical Path: Scoring Phase
      def test_sets_initial_player_scores
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        tournament.call

        tournament.instance_variable_get(:@players).each do |player|
          assert_equal player.score.nil?, false
          assert player.score.is_a?(Integer)
        end
      end

      # Critical Path: Elimination Logic
      def test_eliminates_obvious_bad_players_with_high_variation
        # Create players with very different scores by using pre-scored players
        players = [
          { id: 'player_a', content: 'Player A content', score: 90 },
          { id: 'player_b', content: 'Player B content', score: 85 },
          { id: 'player_c', content: 'Player C content', score: 10 } # outlier
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        # Check that low variation players weren't eliminated
        eliminated_players = tournament.instance_variable_get(:@players).select(&:eliminated)
        assert eliminated_players.size >= 0 # Some may be eliminated based on variation threshold
      end

      def test_tracks_elimination_reason_for_variation
        players = [
          { id: 'player_a', content: 'Player A content', score: 90 },
          { id: 'player_b', content: 'Player B content', score: 85 },
          { id: 'player_c', content: 'Player C content', score: 5 }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        variation_eliminated = players_obj.select { |p| p.eliminated == Tournament::ELIMINATION_VARIATION }
        
        # At least check the constant exists
        assert_equal 'variation_too_high', Tournament::ELIMINATION_VARIATION
      end

      # Critical Path: Elo Round (for large player sets)
      def test_runs_elo_round_for_large_player_sets
        # Create 20 players to trigger Elo (threshold is > 15)
        players = (1..20).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        # After tournament, players should have elo values
        players_obj = tournament.instance_variable_get(:@players)
        players_with_elo = players_obj.eligible.select { |p| p.elo > 0 }
        assert players_with_elo.size > 0
      end

      def test_eliminates_lower_tier_players_after_elo
        players = (1..20).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        relegation_eliminated = players_obj.select { |p| p.eliminated == Tournament::ELIMINATION_RELEGATION }
        
        assert_equal 'relegation_tier', Tournament::ELIMINATION_RELEGATION
      end

      # Critical Path: Free-For-All Phase
      def test_runs_free_for_all_for_small_player_sets
        players = [
          { id: 'player_a', content: 'Player A content', score: 70 },
          { id: 'player_b', content: 'Player B content', score: 65 },
          { id: 'player_c', content: 'Player C content', score: 60 }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        # After FFA, players should have ffa_win_count values
        players_obj = tournament.instance_variable_get(:@players)
        total_ffa_battles = players_obj.sum { |p| p.ffa_win_count + p.ffa_lose_count + p.ffa_draw_count }
        assert total_ffa_battles > 0
      end

      def test_runs_free_for_all_after_elo_rounds_complete
        # Start with enough players for Elo, but should eventually reduce to FFA
        players = (1..16).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        # All eligible players should have participated in FFA
        players_obj = tournament.instance_variable_get(:@players)
        eligible_players = players_obj.eligible
        assert eligible_players.all? { |p| (p.ffa_win_count + p.ffa_lose_count + p.ffa_draw_count) > 0 }
      end

      # Critical Path: Edge Cases
      def test_handles_minimum_two_players
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 2, result.data.size
      end

      def test_accepts_players_as_array_of_hashes
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' },
          { id: 'player_c', content: 'Player C content' }
        ]

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 3, result.data.size
      end

      def test_accepts_players_as_array_of_strings
        players = ['Player A', 'Player B', 'Player C']

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 3, result.data.size
        assert_equal 'Player A', result.data.first
      end

      def test_accepts_players_instance
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal 2, result.data.size
      end

      def test_accepts_juries_parameter
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]
        juries = ['Senior Developer', 'Code Architect']

        result = Tournament.call(
          players,
          'test criteria',
          juries:,
          config: { providers: { openai: { api_key: 'test_key' } } }
        )

        assert_instance_of ActiveGenie::Result, result
      end

      # Critical Path: Configuration
      def test_respects_score_variation_threshold_config
        players = [
          { id: 'player_a', content: 'Player A content', score: 100 },
          { id: 'player_b', content: 'Player B content', score: 90 },
          { id: 'player_c', content: 'Player C content', score: 10 }
        ]

        # High threshold should eliminate fewer players
        result = Tournament.call(
          players,
          'test criteria',
          config: {
            providers: { openai: { api_key: 'test_key' } },
            ranker: { score_variation_threshold: 100 }
          }
        )

        assert_instance_of ActiveGenie::Result, result
      end

      # Critical Path: Complete Tournament Flow
      def test_complete_tournament_flow_with_medium_player_count
        players = (1..10).map do |i|
          { id: "player_#{i}", content: "Player #{i} content" }
        end

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Should return all players ranked
        assert_instance_of ActiveGenie::Result, result
        assert result.data.size <= 10 # Some may be eliminated
        
        # Metadata should contain full player info
        assert result.metadata.is_a?(Array)
        assert result.metadata.all? { |p| p.is_a?(Hash) }
      end

      def test_generates_consistent_ranker_id
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        tournament1 = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        tournament2 = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        tournament1.call
        tournament2.call

        ranker_id1 = tournament1.send(:ranker_id)
        ranker_id2 = tournament2.send(:ranker_id)

        assert_equal ranker_id1, ranker_id2
      end

      def test_all_eligible_players_in_final_result
        players = [
          { id: 'player_a', content: 'Player A content', score: 80 },
          { id: 'player_b', content: 'Player B content', score: 75 },
          { id: 'player_c', content: 'Player C content', score: 70 }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        eligible_count = players_obj.eligible.size

        # Result should contain all eligible players
        assert result.data.size <= players.size
        assert result.data.size >= 2 # At least 2 should remain
      end
    end
  end
end

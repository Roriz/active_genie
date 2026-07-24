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
          assert player_data.key?(:elo)
          assert player_data.key?(:eliminated)
        end
      end

      # Critical Path: Scoring Phase
      def test_sets_initial_player_scores
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        assert_instance_of ActiveGenie::Result, result
        tournament.instance_variable_get(:@players).each do |player|
          refute_nil player.score
          assert player.score.is_a?(Integer)
        end
      end

      # Critical Path: Variation Elimination Logic
      def test_eliminates_obvious_bad_players_with_high_variation
        players = [
          { id: 'player_a', content: 'Player A content', score: 90 },
          { id: 'player_b', content: 'Player B content', score: 85 },
          { id: 'player_c', content: 'Player C content', score: 5 } # outlier
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        eliminated_players = players_obj.select(&:eliminated)

        assert_equal 1, eliminated_players.size
        assert_equal 'player_c', eliminated_players.first.id
        assert_equal Tournament::ELIMINATION_VARIATION, eliminated_players.first.eliminated

        c_meta = result.metadata.find { |m| m[:id] == 'player_c' }
        assert_equal 'variation_too_high', c_meta[:eliminated]

        a_meta = result.metadata.find { |m| m[:id] == 'player_a' }
        assert_nil a_meta[:eliminated]
      end

      def test_tracks_elimination_reason_for_variation
        players = [
          { id: 'player_a', content: 'Player A content', score: 90 },
          { id: 'player_b', content: 'Player B content', score: 85 },
          { id: 'player_c', content: 'Player C content', score: 5 }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        variation_eliminated = players_obj.select { |p| p.eliminated == Tournament::ELIMINATION_VARIATION }

        assert_equal 1, variation_eliminated.size
        assert_equal 'player_c', variation_eliminated.first.id
        assert_equal 'variation_too_high', Tournament::ELIMINATION_VARIATION
      end

      def test_equal_scores_does_not_trigger_variation_elimination
        players = [
          { id: 'player_a', content: 'Player A content', score: 80 },
          { id: 'player_b', content: 'Player B content', score: 80 },
          { id: 'player_c', content: 'Player C content', score: 80 }
        ]

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        players_obj = tournament.instance_variable_get(:@players)
        variation_eliminated = players_obj.select { |p| p.eliminated == Tournament::ELIMINATION_VARIATION }

        assert_empty variation_eliminated
        assert_equal 3, result.data.size
      end

      # Critical Path: Elo Round (for large player sets)
      def test_runs_elo_round_for_large_player_sets
        players = (1..20).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        assert_instance_of ActiveGenie::Result, result
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

        assert_instance_of ActiveGenie::Result, result
        players_obj = tournament.instance_variable_get(:@players)
        relegation_eliminated = players_obj.select { |p| p.eliminated == Tournament::ELIMINATION_RELEGATION }

        refute_empty relegation_eliminated
        assert relegation_eliminated.all? { |p| p.eliminated == 'relegation_tier' }
        assert_equal 'relegation_tier', Tournament::ELIMINATION_RELEGATION
      end

      # Critical Path: Elo Rebalancing
      def test_rebalance_players_increases_elo_for_non_participants_when_highest_elo_diff_positive
        players = (1..18).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50, elo: 1000 }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        players_obj = tournament.instance_variable_get(:@players)

        # Mock-free result structure returned by Elo.call
        elo_result = ActiveGenie::Result.new(
          data: [],
          metadata: {
            highest_elo_diff: 25,
            players_in_round: ['player_1', 'player_2']
          }
        )

        tournament.send(:rebalance_players!, elo_result)

        # Participants in round should NOT be boosted by rebalance
        assert_equal 1000, players_obj.find { |p| p.id == 'player_1' }.elo
        assert_equal 1000, players_obj.find { |p| p.id == 'player_2' }.elo

        # Non-participants should have elo boosted by highest_elo_diff (25)
        assert_equal 1025, players_obj.find { |p| p.id == 'player_3' }.elo
        assert_equal 1025, players_obj.find { |p| p.id == 'player_18' }.elo
      end

      def test_rebalance_players_does_nothing_when_highest_elo_diff_is_negative
        players = (1..18).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50, elo: 1000 }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        players_obj = tournament.instance_variable_get(:@players)

        elo_result = ActiveGenie::Result.new(
          data: [],
          metadata: {
            highest_elo_diff: -15,
            players_in_round: ['player_1']
          }
        )

        tournament.send(:rebalance_players!, elo_result)

        # All players keep original elo
        players_obj.eligible.each do |player|
          assert_equal 1000, player.elo
        end
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

        assert_instance_of ActiveGenie::Result, result
        players_obj = tournament.instance_variable_get(:@players)
        total_ffa_battles = players_obj.sum { |p| p.ffa_win_count + p.ffa_lose_count + p.ffa_draw_count }
        assert total_ffa_battles > 0
      end

      def test_runs_free_for_all_after_elo_rounds_complete
        players = (1..16).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        assert_instance_of ActiveGenie::Result, result
        players_obj = tournament.instance_variable_get(:@players)
        eligible_players = players_obj.eligible
        assert eligible_players.all? { |p| (p.ffa_win_count + p.ffa_lose_count + p.ffa_draw_count) > 0 }
      end

      # Critical Path: Edge Cases & Parameters
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

      def test_juries_parameter_normalization_and_handling
        players = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]

        # Array with duplicates and nils
        tournament1 = Tournament.new(
          players,
          'test criteria',
          juries: ['Senior Developer', nil, 'Senior Developer', 'Code Architect'],
          config: { providers: { openai: { api_key: 'test_key' } } }
        )
        assert_equal ['Senior Developer', 'Code Architect'], tournament1.instance_variable_get(:@juries)

        # Single string jury
        tournament2 = Tournament.new(
          players,
          'test criteria',
          juries: 'Code Architect',
          config: { providers: { openai: { api_key: 'test_key' } } }
        )
        assert_equal ['Code Architect'], tournament2.instance_variable_get(:@juries)

        # nil jury
        tournament3 = Tournament.new(
          players,
          'test criteria',
          juries: nil,
          config: { providers: { openai: { api_key: 'test_key' } } }
        )
        assert_equal [], tournament3.instance_variable_get(:@juries)
      end

      # Critical Path: Configuration
      def test_respects_score_variation_threshold_config
        players = [
          { id: 'player_a', content: 'Player A content', score: 100 },
          { id: 'player_b', content: 'Player B content', score: 90 },
          { id: 'player_c', content: 'Player C content', score: 10 } # outlier
        ]

        # High threshold (100) prevents eliminating the outlier
        tournament_high = Tournament.new(
          players,
          'test criteria',
          config: {
            providers: { openai: { api_key: 'test_key' } },
            ranker: { score_variation_threshold: 100 }
          }
        )
        result_high = tournament_high.call
        assert result_high.metadata.none? { |m| m[:eliminated] == Tournament::ELIMINATION_VARIATION }

        # Low threshold (5) forces eliminating lower performers
        tournament_low = Tournament.new(
          players,
          'test criteria',
          config: {
            providers: { openai: { api_key: 'test_key' } },
            ranker: { score_variation_threshold: 5 }
          }
        )
        result_low = tournament_low.call
        assert result_low.metadata.any? { |m| m[:eliminated] == Tournament::ELIMINATION_VARIATION }
      end

      # Critical Path: Complete Tournament Flow & Observability
      def test_complete_tournament_flow_with_medium_player_count
        players = (1..10).map do |i|
          { id: "player_#{i}", content: "Player #{i} content" }
        end

        result = Tournament.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert result.data.size <= 10
        assert result.metadata.is_a?(Array)
        assert result.metadata.all? { |p| p.is_a?(Hash) }
      end

      def test_generates_consistent_ranker_id_and_varies_with_inputs
        players1 = [
          { id: 'player_a', content: 'Player A content' },
          { id: 'player_b', content: 'Player B content' }
        ]
        players2 = [
          { id: 'player_x', content: 'Player X content' },
          { id: 'player_y', content: 'Player Y content' }
        ]

        t1 = Tournament.new(players1, 'criteria 1', config: { providers: { openai: { api_key: 'test_key' } } })
        t2 = Tournament.new(players1, 'criteria 1', config: { providers: { openai: { api_key: 'test_key' } } })
        t3 = Tournament.new(players1, 'criteria 2', config: { providers: { openai: { api_key: 'test_key' } } })
        t4 = Tournament.new(players2, 'criteria 1', config: { providers: { openai: { api_key: 'test_key' } } })

        id1 = t1.send(:ranker_id)
        id2 = t2.send(:ranker_id)
        id3 = t3.send(:ranker_id)
        id4 = t4.send(:ranker_id)

        assert_equal id1, id2
        refute_equal id1, id3
        refute_equal id1, id4
      end

      def test_logs_ranker_final_event_on_completion
        players = [
          { id: 'player_a', content: 'Player A content', score: 80 },
          { id: 'player_b', content: 'Player B content', score: 75 }
        ]

        logged_events = []
        config = ActiveGenie.new_configuration({ providers: { openai: { api_key: 'test_key' } } })
        config.log.add_observer(observers: ->(log) { logged_events << log })

        tournament = Tournament.new(players, 'test criteria', config:)
        tournament.call

        ranker_final_log = logged_events.find { |l| l[:code] == :ranker_final }
        refute_nil ranker_final_log
        assert_equal tournament.send(:ranker_id), ranker_final_log[:ranker_id]
        assert_equal 2, ranker_final_log[:players].size
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

        assert_equal players_obj.size, result.data.size
        assert result.data.size >= eligible_count
      end

      def test_metadata_contains_all_players_including_eliminated_ones
        players = (1..20).map do |i|
          { id: "player_#{i}", content: "Player #{i} content", score: i == 20 ? 1 : 50 + i }
        end

        tournament = Tournament.new(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result = tournament.call

        # Metadata retains all 20 players
        assert_equal 20, result.metadata.size
        assert_equal 20, result.data.size

        players_obj = tournament.instance_variable_get(:@players)
        eliminated_count = result.metadata.count { |m| !m[:eliminated].nil? }
        assert_equal 20 - players_obj.eligible.size, eliminated_count

        # Check metadata contains expected fields
        result.metadata.each do |meta|
          assert meta.key?(:id)
          assert meta.key?(:content)
          assert meta.key?(:score)
          assert meta.key?(:elo)
          assert meta.key?(:eliminated)
        end
      end
    end
  end
end


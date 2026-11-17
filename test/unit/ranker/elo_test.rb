# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Ranker
    class EloTest < Minitest::Test
      def setup
        # always return the first player as winner
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
        )
      end

      def test_returns_result_object_with_correct_structure
        players = create_players(2)
        
        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_instance_of Array, result.data
        assert_instance_of Hash, result.metadata
        assert_equal 2, result.data.size
      end

      def test_result_data_contains_sorted_player_contents
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1000 },
            { id: 'player_b', content: 'Player B content', elo: 1000 }
          ]
        )

        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 'Player B content', result.data[0]
        assert_equal 'Player A content', result.data[1]
      end

      def test_metadata_contains_required_fields
        players = create_players(2)
        
        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert result.metadata.key?(:elo_id)
        assert result.metadata.key?(:players)
        assert result.metadata.key?(:players_in_round)
        assert result.metadata.key?(:debates_count)
        assert result.metadata.key?(:total_tokens)
        assert result.metadata.key?(:previous_highest_elo)
        assert result.metadata.key?(:highest_elo)
        assert result.metadata.key?(:highest_elo_diff)
        assert result.metadata.key?(:players_elo_diff)
      end

      def test_elo_updates_after_debates
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1000 },
            { id: 'player_b', content: 'Player B content', elo: 1000 }
          ]
        )

        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Equal ratings: the winner (player_b) gains K/2 and the loser (player_a) loses the same
        assert_equal 984, result.metadata[:players].first.elo
        assert_equal 1016, result.metadata[:players].last.elo
      end

      def test_correct_number_of_debates_calculated
        players = create_players(40)
        
        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # lower_tier size * DEBATE_PER_PLAYER (3)
        assert_equal 39, result.metadata[:debates_count]
      end

      def test_players_in_round_includes_all_tiers
        players = create_players(20, elo_split: true)
        
        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 20, result.metadata[:players_in_round].size
      end

      def test_elo_diff_tracking
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1000 },
            { id: 'player_b', content: 'Player B content', elo: 1000 }
          ]
        )

        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Check that elo_diff is calculated
        assert_instance_of Hash, result.metadata[:players_elo_diff]
        assert_equal(-16, result.metadata[:players_elo_diff]['player_a'])
        assert_equal 16, result.metadata[:players_elo_diff]['player_b']
      end

      # Critical Path: Rating math.
      def test_a_match_the_judge_does_not_decide_is_a_draw
        stub_judge(nil)
        players = create_players(20) # everyone at 1000

        Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Between equal ratings a draw moves nothing; a phantom win for player_b would.
        assert_equal [1000], players.map(&:elo).uniq
      end

      def test_every_match_conserves_the_total_rating
        stub_judge('player_a')
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..20).map { |i| { id: "player_#{i}", content: "Player #{i} content", elo: 900 + (i * 10) } }
        )
        total_before = players.sum(&:elo)

        Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Both new ratings must come from the pre-match ratings, so points only move between the two players.
        assert_equal total_before, players.sum(&:elo)
      end

      def test_highest_elo_tracking
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1000 },
            { id: 'player_b', content: 'Player B content', elo: 1000 }
          ]
        )

        result = Elo.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 1000, result.metadata[:previous_highest_elo]
        assert_equal 1016, result.metadata[:highest_elo]
        assert_equal 16, result.metadata[:highest_elo_diff]
      end

      def test_elo_id_generation_is_consistent
        players = create_players(2)
        
        result1 = Elo.call(players, 'criteria', config: { providers: { openai: { api_key: 'test_key' } } })
        result2 = Elo.call(players, 'criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        # Same players and criteria should generate same elo_id initially
        assert_equal 32, result1.metadata[:elo_id].length # MD5 hash length
        assert_instance_of String, result1.metadata[:elo_id]
      end

      private

      def stub_judge(winner)
        arguments = { impartial_judge_winner: winner, impartial_judge_winner_reasoning: 'stubbed' }.to_json
        stub_request(:post, %r{api\.openai\.com/v1/chat/completions}).to_return(
          body: { choices: [{ message: { tool_calls: [{ function: { arguments: } }] } }],
                  usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }.to_json
        )
      end

      def create_players(count, elo_split: false)
        ActiveGenie::Ranker::Entities::Players.new(
          (1..count).map do |i|
            { 
              id: "player_#{i}", 
              content: "Player #{i} content", 
              elo: elo_split && i <= (count / 2) ? 1200 : 1000
            }
          end
        )
      end
    end
  end
end

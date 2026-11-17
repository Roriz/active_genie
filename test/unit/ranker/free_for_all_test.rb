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

        assert_kind_of String, result.metadata[:free_for_all_id]
        assert_kind_of ActiveGenie::Ranker::Entities::Players, result.metadata[:players]
        assert_equal 1, result.metadata[:debates_count]
        assert_kind_of Float, result.metadata[:duration_seconds]
        assert_kind_of Integer, result.metadata[:total_tokens]
      end

      # Critical Path: Observability. Every entry logged during a free-for-all,
      # including the comparator's provider calls, carries its id.
      def test_every_log_entry_carries_the_free_for_all_id
        logs = []
        players = [{ id: 'player_a', content: 'Player A content' }, { id: 'player_b', content: 'Player B content' }]

        result = FreeForAll.call(players, 'test criteria', config: {
                                   providers: { openai: { api_key: 'test_key' } },
                                   log: { output: ->(log) { logs << log } }
                                 })

        id = result.metadata[:free_for_all_id]

        assert_includes logs.map { |log| log[:code] }, :llm_usage
        logs.each { |log| assert_equal id, log[:free_for_all_id], "#{log[:code]} entry is missing the id" }
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

          assert_operator total_battles, :>, 0, "Player #{player.id} should have participated in battles"
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

      # Critical Path: Winner attribution
      # The judge stub decides by content, so these hold whatever order matches are paired in.
      def test_credits_the_judged_winner_when_players_are_hashes
        stub_judge { |a, b| winner_by_content(a, b) }
        players = ActiveGenie::Ranker::Entities::Players.new(
          [{ id: 'weak', content: { name: 'Weak' } }, { id: 'strong', content: { name: 'Strong' } }]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal [{ name: 'Strong' }, { name: 'Weak' }], result.data
        assert_equal [1, 0, 0], ffa_counts(players, 'strong')
        assert_equal [0, 1, 0], ffa_counts(players, 'weak')
      end

      def test_credits_the_judged_winner_when_players_are_strings
        stub_judge { |a, b| winner_by_content(a, b) }
        players = ActiveGenie::Ranker::Entities::Players.new(
          [{ id: 'weak', content: 'Weak' }, { id: 'strong', content: 'Strong' }]
        )

        result = FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal %w[Strong Weak], result.data
        assert_equal [1, 0, 0], ffa_counts(players, 'strong')
        assert_equal [0, 1, 0], ffa_counts(players, 'weak')
      end

      def test_records_a_draw_when_the_judge_picks_no_winner
        stub_judge { nil }
        players = ActiveGenie::Ranker::Entities::Players.new(
          [{ id: 'player_a', content: 'Player A content' }, { id: 'player_b', content: 'Player B content' }]
        )

        FreeForAll.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal [0, 0, 1], ffa_counts(players, 'player_a')
        assert_equal [0, 0, 1], ffa_counts(players, 'player_b')
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

      private

      # Stubs the comparator's LLM call. The block receives the player_a and
      # player_b message contents and returns 'player_a', 'player_b' or nil.
      def stub_judge
        stub_request(:post, %r{api\.openai\.com/v1/chat/completions}).to_return do |req|
          messages = JSON.parse(req.body)['messages']
          winner = yield(messages[1]['content'], messages[2]['content'])
          arguments = { impartial_judge_winner: winner, impartial_judge_winner_reasoning: 'stubbed' }.to_json
          { body: { choices: [{ message: { tool_calls: [{ function: { arguments: } }] } }],
                    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }.to_json }
        end
      end

      def winner_by_content(player_a_message, _player_b_message)
        player_a_message.include?('Strong') ? 'player_a' : 'player_b'
      end

      def ffa_counts(players, id)
        player = players.find { |p| p.id == id }
        [player.ffa_win_count, player.ffa_lose_count, player.ffa_draw_count]
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranker
    class ScoringTest < Minitest::Test
      def setup
        # Stub scorer requests to return a score
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
        )
      end

      def test_scoring_assigns_scores_to_players_without_scores
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: nil },
            { id: 'player_b', content: 'Player B content', score: nil },
            { id: 'player_c', content: 'Player C content', score: 50 } # already has a score
          ]
        )
        criteria = 'test criteria for scoring'

        result = Scoring.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_instance_of ActiveGenie::Result, result
        assert_equal ['Player A content', 'Player B content', 'Player C content'], result.data

        player_a = players.find { |p| p.id == 'player_a' }
        player_b = players.find { |p| p.id == 'player_b' }
        player_c = players.find { |p| p.id == 'player_c' }

        assert_equal 62, player_a.score, 'Player A should have received a score'
        assert_equal 62, player_b.score, 'Player B should have received a score'
        assert_equal 50, player_c.score, 'Player C score should remain unchanged'
      end

      def test_scoring_does_not_rescore_players_with_existing_scores
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: 80 },
            { id: 'player_b', content: 'Player B content', score: 90 }
          ]
        )
        criteria = 'test criteria'

        # Should not make any API calls since all players already have scores
        Scoring.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_not_requested(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)

        player_a = players.find { |p| p.id == 'player_a' }
        player_b = players.find { |p| p.id == 'player_b' }

        assert_equal 80, player_a.score
        assert_equal 90, player_b.score
      end

      def test_scoring_with_custom_juries
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: nil },
            { id: 'player_b', content: 'Player B content', score: nil }
          ]
        )
        criteria = 'evaluate code quality'
        juries = ['Senior Developer', 'Code Architect']

        Scoring.call(players, criteria, juries:, config: { providers: { openai: { api_key: 'test_key' } } })

        # Verify that both players received scores
        players.each do |player|
          assert_equal 62, player.score
        end
      end

      def test_scoring_handles_empty_player_list
        players = ActiveGenie::Ranker::Entities::Players.new([])
        criteria = 'test criteria'

        # Should not raise an error
        assert_silent do
          Scoring.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })
        end

        # Should not make any API calls
        assert_not_requested(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
      end

      def test_scoring_with_auto_generated_juries
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: nil }
          ]
        )
        criteria = 'code quality'

        # Mock Lister.juries to return a list
        ActiveGenie::Lister::Juries.stub :call, lambda { |_text, _criteria, **|
          ActiveGenie::Result.new(data: ['Code Reviewer', 'Senior Developer'], reasoning: 'test', metadata: {})
        } do
          Scoring.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })
        end

        # Should have scored the player using auto-generated juries
        assert_equal 62, players.first.score
      end

      def test_scoring_with_empty_juries_array_triggers_auto_generation
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: nil }
          ]
        )
        criteria = 'code quality'

        juries_called = false
        ActiveGenie::Lister::Juries.stub :call, lambda { |_text, _criteria, **|
          juries_called = true
          ActiveGenie::Result.new(data: ['Code Reviewer'], reasoning: 'test', metadata: {})
        } do
          # Empty array should trigger auto-generation
          Scoring.call(players, criteria, juries: [], config: { providers: { openai: { api_key: 'test_key' } } })
        end

        assert juries_called, 'Empty juries array should trigger auto-generation'
        assert_equal 62, players.first.score
      end

      # Critical Path: Consistency. Players ranked against each other must be
      # scored by the same jury, or their scores are not comparable.
      def test_auto_generated_juries_are_listed_once_and_shared_by_every_player
        jury_requests = 0
        juries_seen_by_scorer = []
        stub_request(:post, %r{api\.openai\.com/v1/chat/completions}).to_return do |req|
          function = JSON.parse(req.body).dig('tools', 0, 'function')
          if function['name'] == 'identify_jury'
            jury_requests += 1
            openai_tool_response(juries: ["Expert #{jury_requests}"], why_these_juries: 'stubbed')
          else
            juries_seen_by_scorer << function.dig('parameters', 'properties').keys.grep(/_score\z/)
            openai_tool_response(final_score: 50, final_reasoning: 'stubbed')
          end
        end
        players = ActiveGenie::Ranker::Entities::Players.new(
          (1..3).map { |i| { id: "player_#{i}", content: "Player #{i} content" } }
        )

        Scoring.call(players, 'test criteria', config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 1, jury_requests
        assert_equal [%w[expert_1_score final_score]] * 3, juries_seen_by_scorer
      end

      def test_scoring_with_mixed_scored_and_unscored_players
        players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', score: 85 },
            { id: 'player_b', content: 'Player B content', score: nil },
            { id: 'player_c', content: 'Player C content', score: 70 },
            { id: 'player_d', content: 'Player D content', score: nil }
          ]
        )
        criteria = 'test criteria'

        Scoring.call(players, criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 85, players.find { |p| p.id == 'player_a' }.score
        assert_equal 62, players.find { |p| p.id == 'player_b' }.score
        assert_equal 70, players.find { |p| p.id == 'player_c' }.score
        assert_equal 62, players.find { |p| p.id == 'player_d' }.score
      end

      private

      def openai_tool_response(arguments)
        { body: { choices: [{ message: { tool_calls: [{ function: { arguments: arguments.to_json } }] } }],
                  usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }.to_json }
      end
    end
  end
end

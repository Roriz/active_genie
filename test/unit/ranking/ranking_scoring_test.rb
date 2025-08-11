# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranking
    class RankingScoringTest < Minitest::Test
      def setup
        @players = ActiveGenie::Ranking::PlayersCollection.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )
        @criteria = 'test criteria'
      end

      def test_scoring_is_called_with_correct_arguments
        scoring_mock = Minitest::Mock.new
        scoring_mock.expect(:call, { 'final_score' => 50, 'final_reasoning' => 'reason' }) do |*args|
          assert_equal @players.first.content, args[0]
          assert_equal @criteria, args[1]
        end
        scoring_mock.expect(:call, { 'final_score' => 50, 'final_reasoning' => 'reason' }) do |*args|
          assert_equal @players.last.content, args[0]
          assert_equal @criteria, args[1]
        end

        ActiveGenie::Scoring.stub(:call, ->(*args) { scoring_mock.call(*args) }) do
          RankingScoring.call(@players, @criteria)
        end

        assert_mock scoring_mock
      end

      def test_updates_players_score
        scoring_mock = Minitest::Mock.new
        scoring_mock.expect(:call, { 'final_score' => 50, 'final_reasoning' => 'reason' }, 2)

        ActiveGenie::Scoring.stub(:call, ->(*args) { scoring_mock.call(*args) }) do
          RankingScoring.call(@players, @criteria)
        end

        assert_equal 50, @players.first.score
        assert_equal 50, @players.last.score
      end

      def test_recommended_reviewers_is_called_when_no_reviewers_are_provided
        reviewers_mock = Minitest::Mock.new
        reviewers_mock.expect(:call, { 'reviewer1' => 'r1', 'reviewer2' => 'r2', 'reviewer3' => 'r3' })
        scoring_mock = Minitest::Mock.new
        scoring_mock.expect(:call, { 'final_score' => 50, 'final_reasoning' => 'reason' }, 2)

        ActiveGenie::Scoring::RecommendedReviewers.stub(:call, ->(*args) { reviewers_mock.call(*args) }) do
          ActiveGenie::Scoring.stub(:call, ->(*args) { scoring_mock.call(*args) }) do
            RankingScoring.call(@players, @criteria)
          end
        end

        assert_mock reviewers_mock
      end
    end
  end
end

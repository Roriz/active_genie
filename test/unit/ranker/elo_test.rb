# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranker
    class EloTest < Minitest::Test
      def setup
        @players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1001 },
            { id: 'player_b', content: 'Player B content', elo: 999 }
          ]
        )
        @criteria = 'test criteria'
      end

      def test_debate_is_called_with_correct_arguments
        debate_mock = Minitest::Mock.new
        debate_mock.expect(:call, { 'winner' => 'player_a' }) do |*args|
          assert_equal @players.map(&:content).include?(args[0]), true
          assert_equal @players.map(&:content).include?(args[1]), true
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Comparator.stub(:by_debate, ->(*args) { debate_mock.call(*args) }) do
          Elo.call(@players, @criteria)
        end

        assert_mock debate_mock
      end

      def test_updates_elo_after_debate
        debate_mock = Minitest::Mock.new
        debate_mock.expect(
          :call,
          { 'winner' => 'player_a' }
        ) do |*args|
          assert_equal @players.map(&:content).include?(args[0]), true
          assert_equal @players.map(&:content).include?(args[1]), true
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Comparator.stub(:by_debate, ->(*args) { debate_mock.call(*args) }) do
          Elo.call(@players, @criteria)
        end

        assert_equal 1001, @players.first.elo
        assert_equal 999, @players.last.elo
      end
    end
  end
end

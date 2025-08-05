# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranking
    class EloRoundTest < Minitest::Test
      def setup
        @players = ActiveGenie::Ranking::PlayersCollection.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1001 },
            { id: 'player_b', content: 'Player B content', elo: 999 }
          ]
        )
        @criteria = 'test criteria'
      end

      def test_battle_is_called_with_correct_arguments
        battle_mock = Minitest::Mock.new
        battle_mock.expect(:call, { 'winner' => 'player_a' }) do |*args|
          assert_equal @players.last.content, args[0]
          assert_equal @players.first.content, args[1]
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          EloRound.call(@players, @criteria)
        end

        assert_mock battle_mock
      end

      def test_updates_elo_after_battle
        battle_mock = Minitest::Mock.new
        battle_mock.expect(
          :call,
          { 'winner' => 'player_a' }
        ) do |*args|
          assert_equal @players.last.content, args[0]
          assert_equal @players.first.content, args[1]
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          EloRound.call(@players, @criteria)
        end

        assert_equal 986, @players.first.elo
        assert_equal 1015, @players.last.elo
      end
    end
  end
end

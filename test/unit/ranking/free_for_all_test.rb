# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

module ActiveGenie
  module Ranking
    class FreeForAllTest < Minitest::Test
      def setup
        @players = ActiveGenie::Ranking::PlayersCollection.new(
          [
            { id: 'player_a', content: 'Player A content' },
            { id: 'player_b', content: 'Player B content' }
          ]
        )
        @criteria = 'test criteria'
      end

      def test_battle_is_called_with_correct_arguments
        battle_mock = Minitest::Mock.new
        battle_mock.expect(:call, { 'winner' => 'player_a' }) do |*args|
          assert_equal @players.first.content, args[0]
          assert_equal @players.last.content, args[1]
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          FreeForAll.call(@players, @criteria)
        end

        assert_mock battle_mock
      end

      def test_updates_players_score_after_battle
        battle_mock = Minitest::Mock.new
        battle_mock.expect(
          :call,
          { 'winner' => 'player_a' }
        ) do |*args|
          assert_equal @players.first.content, args[0]
          assert_equal @players.last.content, args[1]
          assert_equal @criteria, args[2]
          assert_instance_of ActiveGenie::Configuration, args[3][:config]
        end

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          FreeForAll.call(@players, @criteria)
        end

        assert_equal 1, @players.first.ffa_win_count
        assert_equal 1, @players.last.ffa_lose_count
      end
    end
  end
end

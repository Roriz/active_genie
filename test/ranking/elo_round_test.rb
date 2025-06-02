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
        battle_mock.expect(
          :call,
          { 'winner' => 'player_a' },
          [@players.last.content, @players.first.content, @criteria, { config: {} }]
        )

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          EloRound.call(@players, @criteria)
        end

        assert_mock battle_mock
      end

      def test_updates_elo_after_battle
        battle_mock = Minitest::Mock.new
        battle_mock.expect(
          :call,
          { 'winner' => 'player_a' },
          [@players.last.content, @players.first.content, @criteria, { config: {} }]
        )

        ActiveGenie::Battle.stub(:call, ->(*args) { battle_mock.call(*args) }) do
          EloRound.call(@players, @criteria)
        end

        assert_equal @players.first.elo, 986
        assert_equal @players.last.elo, 1015
      end
    end
  end
end

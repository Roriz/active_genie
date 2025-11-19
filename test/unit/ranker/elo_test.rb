# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'
require 'minitest/mock'

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

      def test_elo_ranking_return_correct_order
        @players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1001 }, # winner
            { id: 'player_b', content: 'Player B content', elo: 999 } # loser
          ]
        )
        @criteria = 'test criteria'

        result = Elo.call(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert result.data[0], 'Player A content'
        assert result.data[1], 'Player B content'

        @players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_b', content: 'Player B content', elo: 999 }, # winner
            { id: 'player_a', content: 'Player A content', elo: 1001 } # loser
          ]
        )
        result = Elo.call(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert result.data[0], 'Player B content'
        assert result.data[1], 'Player A content'
      end

      def test_elo_calculates_elo_correctly
        @players = ActiveGenie::Ranker::Entities::Players.new(
          [
            { id: 'player_a', content: 'Player A content', elo: 1000 },
            { id: 'player_b', content: 'Player B content', elo: 1000 }
          ]
        )
        @criteria = 'test criteria'

        result = Elo.call(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 1016, result.metadata[:players].first.elo
        assert_equal 985, result.metadata[:players].last.elo
      end

      def test_amount_of_matches
        @players = ActiveGenie::Ranker::Entities::Players.new(
          (1..40).map { |i| { id: "player_#{i}", content: "Player #{i} content", elo: 1000 } }
        )
        @criteria = 'test criteria'

        result = Elo.call(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })

        assert_equal 39, result.metadata[:debates_count]
      end

      def test_matches_are_unique_and_between_higher_and_lower_tiers
        @players = ActiveGenie::Ranker::Entities::Players.new(
          (1..20).map { |i| { id: "player_#{i}", content: "Player #{i} content", elo: i <= 10 ? 1200 : 800 } }
        )
        @criteria = 'test criteria'

        elo_instance = Elo.new(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })
        elo_instance.call

        matches = elo_instance.instance_variable_get(:@matches).map { |player_a, player_b| [player_a.id, player_b.id] }

        assert_equal 30, matches.count
        assert_equal [
          %w[player_1 player_11],
          %w[player_1 player_12],
          %w[player_1 player_13],
          %w[player_2 player_14],
          %w[player_2 player_15],
          %w[player_2 player_16],
          %w[player_3 player_17],
          %w[player_3 player_18],
          %w[player_3 player_19],
          %w[player_4 player_20],
          %w[player_4 player_11],
          %w[player_4 player_12],
          %w[player_5 player_13],
          %w[player_5 player_14],
          %w[player_5 player_15],
          %w[player_6 player_16],
          %w[player_6 player_17],
          %w[player_6 player_18],
          %w[player_7 player_19],
          %w[player_7 player_20],
          %w[player_7 player_11],
          %w[player_8 player_12],
          %w[player_8 player_13],
          %w[player_8 player_14],
          %w[player_9 player_15],
          %w[player_9 player_16],
          %w[player_9 player_17],
          %w[player_10 player_18],
          %w[player_10 player_19],
          %w[player_10 player_20]
        ], matches
      end
    end
  end
end

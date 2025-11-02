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
            { id: 'player_a', content: 'Player A content', elo: 1001 }, # loser
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

        assert_equal result.metadata[:players].first.elo, 1016
        assert_equal result.metadata[:players].last.elo, 985
      end

      def test_amount_of_matches
        @players = ActiveGenie::Ranker::Entities::Players.new(
          (1..40).map { |i| { id: "player_#{i}", content: "Player #{i} content", elo: 1000 } }
        )
        @criteria = 'test criteria'

        result = Elo.call(@players, @criteria, config: { providers: { openai: { api_key: 'test_key' } } })
        assert_equal result.metadata[:debates_count], 39
      end
    end
  end
end

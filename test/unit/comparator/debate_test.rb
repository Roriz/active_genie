# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Comparator
    class DebateTest < Minitest::Test
      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
        )

        player_a = 'Player A content'
        player_b = 'Player B content'
        criteria = 'Evaluate based on creativity and clarity'

        ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          system_message = messages.find { |m| m['role'] == 'system' }

          assert_includes system_message['content'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{player_b}" }

          assert(request_body['tools'].any? { |t| t['type'] == 'function' })
        end
      end
    end
  end
end

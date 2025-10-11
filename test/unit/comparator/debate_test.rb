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

        result = ActiveGenie::Comparator.by_debate(
          player_a,
          player_b,
          criteria,
          config: {
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

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

        assert_equal 'Player A content', result.data
        assert_equal 'Maintainability hinges on modularity and ease of change. While coverage is valuable for safety, tightly coupled code remains hard to evolve. Dependency injection demonstrably improves modularity and reduces maintenance risk, so it better meets the criteria.', result.reasoning
      end

      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-google.json")
        )

        player_a = 'Player A content'
        player_b = 'Player B content'
        criteria = 'Evaluate based on creativity and clarity'

        result = ActiveGenie::Comparator.by_debate(
          player_a,
          player_b,
          criteria,
          config: {
            providers: { google: { api_key: 'google_secret' } }
          }
        )

        assert_requested(:post,
                         %r{https://generativelanguage\.googleapis\.com/v1beta/models/.*:generateContent}) do |req|
          request_body = JSON.parse(req.body)
          contents = request_body['contents']

          assert_includes contents[0]['parts'][0]['text'], 'Based on two players, player_a and player_b'
          assert_equal 'user', contents[0]['role']
          assert_equal 'user', contents[1]['role']

          text_parts = contents.flat_map { |c| c['parts'].map { |p| p['text'] } }
          assert_includes text_parts, "criteria: #{criteria}"
          assert_includes text_parts, "player_a: #{player_a}"
          assert_includes text_parts, "player_b: #{player_b}"
        end
        assert_equal 'Player A content', result.data
        assert_equal 'Player_a\'s emphasis on dependency injection directly addresses fundamental aspects of code quality and maintainability by reducing coupling and enhancing modularity. While player_b\'s high test coverage is commendable for quality, the admission of tightly coupled components is a significant detriment to long-term maintainability. Tightly coupled systems, even with high test coverage, are harder to evolve and refactor. Player_a\'s approach fosters a more robust, adaptable, and inherently maintainable codebase from its architectural foundation, making it superior in the long run.', result.reasoning
      end

      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-deepseek.json")
        )

        player_a = 'Player A content'
        player_b = 'Player B content'
        criteria = 'Evaluate based on creativity and clarity'

        result = ActiveGenie::Comparator.by_debate(
          player_a,
          player_b,
          criteria,
          config: {
            providers: { deepseek: { api_key: 'deepseek_secret' } }
          }
        )

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          system_message = messages.find { |m| m['role'] == 'system' }

          assert_includes system_message['content'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{player_b}" }

          assert(request_body['tools'].any? { |t| t['type'] == 'function' })
        end
        assert_equal 'Player A content', result.data
        assert_equal 'While both approaches have merits, code quality and maintainability favor player_a\'s dependency injection. Tight coupling creates technical debt that grows over time, making changes riskier and more expensive. High test coverage is valuable but doesn\'t address architectural flaws. Dependency injection promotes better separation of concerns, easier testing, and long-term maintainability. The initial complexity investment pays dividends in reduced maintenance costs and greater flexibility for future enhancements.', result.reasoning
      end

      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-anthropic.json")
        )

        player_a = 'Player A content'
        player_b = 'Player B content'
        criteria = 'Evaluate based on creativity and clarity'

        result = ActiveGenie::Comparator.by_debate(
          player_a,
          player_b,
          criteria,
          config: {
            providers: { anthropic: { api_key: 'anthropic_secret' } }
          }
        )

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_includes request_body['system'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{player_b}" }
        end

        assert_equal 'Player A content', result.data
        assert_equal 'While test coverage is important, dependency injection offers superior code maintainability and testability. Loose coupling enables easier modifications, better separation of concerns, and more flexible software design.', result.reasoning
      end
    end
  end
end
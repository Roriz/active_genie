# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Comparator
    class DebateTest < Minitest::Test
      def setup
        @player_a = 'Player A content'
        @player_b = 'Player B content'
        @criteria = 'Evaluate based on creativity and clarity'
      end

      # Critical Path: Provider Requests & Integration
      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
        )

        result = ActiveGenie::Comparator.by_debate(
          @player_a,
          @player_b,
          @criteria,
          config: {
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          system_message = messages.find { |m| m['role'] == 'system' }

          assert_includes system_message['content'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{@criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{@player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{@player_b}" }

          assert(request_body['tools'].any? { |t| t['type'] == 'function' })
        end

        assert_equal 'Player A content', result.data
        assert_includes result.reasoning, 'Maintainability hinges on modularity and ease of change'
        assert_instance_of Hash, result.metadata
        assert_equal 'player_a', result.metadata['impartial_judge_winner']
      end

      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-google.json")
        )

        result = ActiveGenie::Comparator.by_debate(
          @player_a,
          @player_b,
          @criteria,
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

          assert_includes text_parts, "criteria: #{@criteria}"
          assert_includes text_parts, "player_a: #{@player_a}"
          assert_includes text_parts, "player_b: #{@player_b}"
        end

        assert_equal 'Player A content', result.data
        assert_includes result.reasoning, 'Player_a\'s emphasis on dependency injection'
        assert_instance_of Hash, result.metadata
      end

      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-deepseek.json")
        )

        result = ActiveGenie::Comparator.by_debate(
          @player_a,
          @player_b,
          @criteria,
          config: {
            providers: { deepseek: { api_key: 'deepseek_secret' } }
          }
        )

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          system_message = messages.find { |m| m['role'] == 'system' }

          assert_includes system_message['content'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{@criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{@player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{@player_b}" }

          assert(request_body['tools'].any? { |t| t['type'] == 'function' })
        end

        assert_equal 'Player A content', result.data
        assert_includes result.reasoning, 'code quality and maintainability favor player_a\'s dependency injection'
        assert_instance_of Hash, result.metadata
      end

      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-anthropic.json")
        )

        result = ActiveGenie::Comparator.by_debate(
          @player_a,
          @player_b,
          @criteria,
          config: {
            providers: { anthropic: { api_key: 'anthropic_secret' } }
          }
        )

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_includes request_body['system'], 'Based on two players, player_a and player_b'
          assert_includes messages, { 'role' => 'user', 'content' => "criteria: #{@criteria}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_a: #{@player_a}" }
          assert_includes messages, { 'role' => 'user', 'content' => "player_b: #{@player_b}" }
        end

        assert_equal 'Player A content', result.data
        assert_includes result.reasoning, 'dependency injection offers superior code maintainability'
        assert_instance_of Hash, result.metadata
      end

      # Critical Path: Winner Mapping Variants
      def test_returns_player_b_when_impartial_judge_chooses_player_b
        stub_debate_response(
          winner: 'player_b',
          reasoning: 'Player B provided more comprehensive test coverage and clearer documentation.'
        )

        result = Debate.call(
          @player_a,
          @player_b,
          @criteria,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_equal 'Player B content', result.data
        assert_equal 'Player B provided more comprehensive test coverage and clearer documentation.', result.reasoning
        assert_equal 'player_b', result.metadata['impartial_judge_winner']
      end

      def test_returns_nil_winner_when_impartial_judge_response_is_nil
        stub_debate_response(
          winner: nil,
          reasoning: 'Both players were equal.'
        )

        result = Debate.call(
          @player_a,
          @player_b,
          @criteria,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_nil result.data
        assert_equal 'Both players were equal.', result.reasoning
      end

      # Critical Path: Module Configuration & Delegation
      def test_module_config_recommended_model
        debate_instance = Debate.new(@player_a, @player_b, @criteria)
        config = debate_instance.send(:module_config)

        assert_equal({ llm: { recommended_model: 'claude-haiku-4-5' } }, config)
      end

      def test_comparator_module_delegation_methods
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/comparator-openai.json")
        )

        config = {
          llm: { provider: 'openai' },
          providers: { openai: { api_key: 'openai_secret' } }
        }

        res1 = ActiveGenie::Comparator.call(@player_a, @player_b, @criteria, config:)
        res2 = ActiveGenie::Comparator.by_debate(@player_a, @player_b, @criteria, config:)
        res3 = Debate.call(@player_a, @player_b, @criteria, config:)

        assert_equal res1.data, res2.data
        assert_equal res2.data, res3.data
        assert_equal res1.reasoning, res3.reasoning
      end

      def test_logprobs_winner_determination
        mock_logprobs_response = {
          data: {
            'impartial_judge_winner' => 'player_b',
            'impartial_judge_winner_reasoning' => 'Player A has higher continuous scores.'
          },
          logprobs: {
            'chosenCandidates' => [
              { 'token' => 'player_a_adherence_score' }, { 'token' => '": ' }, { 'token' => '5' },
              { 'token' => 'player_b_adherence_score' }, { 'token' => '": ' }, { 'token' => '2' }
            ],
            'topCandidates' => [
              { 'candidates' => [{ 'token' => 'player_a_adherence_score' }] },
              { 'candidates' => [{ 'token' => '": ' }] },
              { 'candidates' => [{ 'token' => '5', 'logProbability' => -0.1 }, { 'token' => '4', 'logProbability' => -2.0 }] },
              { 'candidates' => [{ 'token' => 'player_b_adherence_score' }] },
              { 'candidates' => [{ 'token' => '": ' }] },
              { 'candidates' => [{ 'token' => '2', 'logProbability' => -0.1 }, { 'token' => '3', 'logProbability' => -2.0 }] }
            ]
          }
        }

        ActiveGenie::Providers::UnifiedProvider.stub(:function_calling, mock_logprobs_response) do
          result = Debate.call(@player_a, @player_b, @criteria)

          assert_equal 'Player A content', result.data
          assert_equal true, result.metadata['logprobs_used']
          assert_equal 'player_a', result.metadata['logprobs_winner']
        end
      end

      private

      def stub_debate_response(winner:, reasoning:)
        arguments_json = {
          impartial_judge_winner: winner,
          impartial_judge_winner_reasoning: reasoning
        }.compact.to_json

        body = {
          choices: [
            {
              message: {
                tool_calls: [
                  {
                    function: {
                      name: 'comparation_through_debate',
                      arguments: arguments_json
                    }
                  }
                ]
              }
            }
          ],
          usage: { prompt_tokens: 100, completion_tokens: 50, total_tokens: 150 }
        }.to_json

        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/)
          .to_return(status: 200, body:)
      end
    end
  end
end


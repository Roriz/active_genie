# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Scorer
    class JuryBenchTest < Minitest::Test
      def setup
        @criteria = 'How much positive sentiment is expressed in the text? Where 0 is very negative, 100 is the most positive as possible.'
        @text_to_score = 'This is the best thing ever!'
      end

      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-anthropic.json")
        )

        result = ActiveGenie::Scorer.by_jury_bench(
          @text_to_score,
          @criteria,
          config: {
            llm: { provider: 'anthropic' },
            providers: { anthropic: { api_key: 'anthropic_secret' } }
          }
        )

        assert_requested(:post, 'https://api.anthropic.com/v1/messages', times: 2) do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_equal messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) }, true
        end

        reasoning = "The text demonstrates a solid understanding of advanced software design principles, with a focus on dependency injection and SOLID principles. While the statement shows awareness of best practices for code quality and maintainability, it lacks specific implementation details. The score reflects a good conceptual approach to software design, with room for more detailed technical elaboration.

Strengths:
- Highlights key design principles
- Emphasizes testability and modular design
- Shows awareness of advanced software architecture concepts

Improvement Opportunities:
- Provide concrete implementation examples
- Elaborate on specific SOLID principle applications
- Offer more context about the actual code structure

The score of 73 places this in the \"Good\" range, indicating a strong conceptual understanding with potential for more detailed technical demonstration."
        assert_equal 73, result.data
        assert_equal reasoning, result.reasoning
      end

      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
        )

        result = ActiveGenie::Scorer.by_jury_bench(
          @text_to_score,
          @criteria,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions', times: 2) do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_equal messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) }, true
        end

        assert_equal 62, result.data
        assert result.reasoning.include?('Both jurors recognize that the practices mentioned (DI and SOLID) are strong indicators')
      end

      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-google.json")
        )

        result = ActiveGenie::Scorer.by_jury_bench(
          @text_to_score,
          @criteria,
          config: {
            llm: { provider: 'google' },
            providers: { google: { api_key: 'google_secret' } }
          }
        )

        assert_requested(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent}, times: 2) do |req|
          request_body = JSON.parse(req.body)
          contents = request_body['contents']

          assert_equal contents.any? { |c| c['parts'].any? { |p| p['text'].include?(@criteria) } }, true
        end

        assert_equal 80, result.data
        expected_reasoning = "The implementation uses dependency injection for better testability and follows SOLID principles"
        assert result.reasoning.include?(expected_reasoning)
      end

      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-deepseek.json")
        )

        result = ActiveGenie::Scorer.by_jury_bench(
          @text_to_score,
          @criteria,
          config: {
            llm: { provider: 'deepseek' },
            providers: { deepseek: { api_key: 'deepseek_secret' } }
          }
        )

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions', times: 2) do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_equal messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) }, true
        end

        reasoning = "The text demonstrates awareness of important software engineering principles"
        assert_equal 72.5, result.data
        assert result.reasoning.include?(reasoning)
      end
    end
  end
end

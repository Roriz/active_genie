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

      # Critical Path: Provider Requests & Unified Provider Integration
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

          assert(messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) })
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
        assert_instance_of Hash, result.metadata
        assert_equal 73, result.metadata['final_score']
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

          assert(messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) })
        end

        assert_equal 62, result.data
        assert_includes result.reasoning,
                        'Both jurors recognize that the practices mentioned (DI and SOLID) are strong indicators'
        assert_instance_of Hash, result.metadata
        assert_equal 62, result.metadata['final_score']
        assert_equal 60, result.metadata['senior_software_engineer_score']
        assert_equal 64, result.metadata['code_architect_score']
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

        assert_requested(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent},
                         times: 2) do |req|
          request_body = JSON.parse(req.body)
          contents = request_body['contents']

          assert(contents.any? { |c| c['parts'].any? { |p| p['text'].include?(@criteria) } })
        end

        assert_equal 80, result.data
        expected_reasoning = 'The implementation uses dependency injection for better testability and follows SOLID principles'

        assert_includes result.reasoning, expected_reasoning
        assert_instance_of Hash, result.metadata
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

          assert(messages.any? { |m| m['role'] == 'user' && m['content'].include?(@criteria) })
        end

        reasoning = 'The text demonstrates awareness of important software engineering principles'

        assert_in_delta(72.5, result.data)
        assert_includes result.reasoning, reasoning
        assert_instance_of Hash, result.metadata
      end

      # Critical Path: Explicit Juries vs Automatic Recommendation
      def test_explicit_juries_skips_lister_juries_call
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
        )

        explicit_juries = ['Grammar Expert', 'Tone Advocate']

        result = JuryBench.call(
          @text_to_score,
          @criteria,
          explicit_juries,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result

        # Exactly 1 HTTP request made (scorer), NO request for Lister::Juries
        assert_requested(:post, 'https://api.openai.com/v1/chat/completions', times: 1) do |req|
          request_body = JSON.parse(req.body)
          tools = request_body['tools']
          scorer_tool = tools.find { |t| t['function']['name'] == 'scorer' }
          props = scorer_tool['function']['parameters']['properties']

          assert props.key?('grammar_expert_score')
          assert props.key?('grammar_expert_reasoning')
          assert props.key?('tone_advocate_score')
          assert props.key?('tone_advocate_reasoning')
          assert props.key?('final_score')
          assert props.key?('final_reasoning')
        end
      end

      def test_omitted_juries_triggers_automatic_juries_recommendation
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
        )

        # Passing empty array triggers automatic jury recommendation via Lister::Juries
        result = JuryBench.call(
          @text_to_score,
          @criteria,
          [],
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_instance_of ActiveGenie::Result, result
        # 2 HTTP requests: 1st for Lister::Juries, 2nd for Scorer
        assert_requested(:post, 'https://api.openai.com/v1/chat/completions', times: 2)
      end

      # Critical Path: Juries Parameter Normalization
      def test_juries_parameter_normalization
        players_text = 'Sample text for scoring'

        jb1 = JuryBench.new(players_text, @criteria, ['Grammar Expert', nil, 'Grammar Expert', 'Tone Advocate'])
        assert_equal ['Grammar Expert', 'Tone Advocate'], jb1.send(:juries)

        jb2 = JuryBench.new(players_text, @criteria, 'Grammar Expert')
        assert_equal ['Grammar Expert'], jb2.send(:juries)

        jb3 = JuryBench.new(players_text, @criteria, nil)
        assert_equal [], jb3.instance_variable_get(:@param_juries)
      end

      # Critical Path: Schema Generation
      def test_function_schema_generation_underscores_jury_names
        jury_bench = JuryBench.new(
          @text_to_score,
          @criteria,
          ['Senior Software Engineer', 'Code Architect']
        )

        function_schema = jury_bench.send(:build_function)

        assert_equal 'scorer', function_schema[:name]
        props = function_schema[:parameters][:properties]

        assert props.key?('senior_software_engineer_score')
        assert props.key?('senior_software_engineer_reasoning')
        assert props.key?('code_architect_score')
        assert props.key?('code_architect_reasoning')
        assert props.key?(:final_score)
        assert props.key?(:final_reasoning)

        assert_equal 'number', props['senior_software_engineer_score'][:type]
        assert_equal 0, props['senior_software_engineer_score'][:min]
        assert_equal 100, props['senior_software_engineer_score'][:max]
      end

      # Critical Path: Fallback Behavior
      def test_fallback_data_score_when_final_score_missing
        # Mock-free testing: Stub provider to return JSON tool response without final_score
        missing_score_json = {
          id: 'chatcmpl-test',
          object: 'chat.completion',
          choices: [
            {
              message: {
                tool_calls: [
                  {
                    function: {
                      name: 'scorer',
                      arguments: JSON.generate({
                        'final_reasoning' => 'Scoring completed but score was omitted'
                      })
                    }
                  }
                ]
              }
            }
          ]
        }.to_json

        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: missing_score_json
        )

        result = JuryBench.call(
          @text_to_score,
          @criteria,
          ['Grammar Expert'],
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_equal 0, result.data
        assert_equal 'Scoring completed but score was omitted', result.reasoning
      end

      # Critical Path: Module Configuration & Delegation
      def test_module_config_recommended_model
        jb = JuryBench.new(@text_to_score, @criteria)
        config = jb.send(:module_config)

        assert_equal({ llm: { recommended_model: 'deepseek-chat' } }, config)
      end

      def test_scorer_module_delegation_methods
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/scorer-openai.json")
        )

        config = {
          llm: { provider: 'openai' },
          providers: { openai: { api_key: 'openai_secret' } }
        }

        res1 = ActiveGenie::Scorer.call(@text_to_score, @criteria, config:)
        res2 = ActiveGenie::Scorer.by_jury_bench(@text_to_score, @criteria, config:)

        assert_equal res1.data, res2.data
        assert_equal res1.reasoning, res2.reasoning
      end

      def test_logprobs_continuous_final_score_calculation
        mock_logprobs_response = {
          data: {
            'final_score' => 80,
            'final_reasoning' => 'High quality response'
          },
          logprobs: {
            'chosenCandidates' => [
              { 'token' => 'final_score' }, { 'token' => '": ' }, { 'token' => '85' }
            ],
            'topCandidates' => [
              { 'candidates' => [{ 'token' => 'final_score' }] },
              { 'candidates' => [{ 'token' => '": ' }] },
              {
                'candidates' => [
                  { 'token' => '85', 'logProbability' => -0.22314 },
                  { 'token' => '80', 'logProbability' => -1.60943 }
                ]
              }
            ]
          }
        }

        ActiveGenie::Providers::UnifiedProvider.stub(:function_calling, mock_logprobs_response) do
          result = JuryBench.call(@text_to_score, @criteria, ['Grammar Expert'])

          assert_in_delta 84.0, result.data, 0.5
          assert_equal 'High quality response', result.reasoning
          assert_equal true, result.metadata['logprobs_used']
          assert_in_delta 84.0, result.metadata['continuous_final_score'], 0.5
        end
      end
    end
  end
end


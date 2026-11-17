# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/unified_provider'

module ActiveGenie
  module Providers
    # Providers sometimes omit token usage, wholly or in part. Every provider
    # must still answer, and :llm_usage must still carry integer counts, since
    # observers (like Ranker's token counters) sum them.
    class MissingUsageTest < Minitest::Test
      FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: { type: 'object', properties: { score: { type: 'integer' } } }
      }.freeze
      MESSAGES = [{ role: 'user', content: 'Score this essay' }].freeze
      OPENAI_STYLE_BODY = { choices: [{ message: { tool_calls: [{ function: { arguments: '{"score":8}' } }] } }] }.freeze

      def setup
        @dir = Dir.mktmpdir
        @logs = []
      end

      def teardown
        super # webmock/minitest resets its request registry here
        FileUtils.remove_entry(@dir)
      end

      def test_openai_without_usage
        stub_request(:post, /api\.openai\.com/).to_return(body: OPENAI_STYLE_BODY.to_json)

        assert_scored OpenaiProvider, 'gpt-5.6-luna', :openai
        assert_usage(input: 0, output: 0, total: 0)
      end

      def test_deepseek_without_usage
        stub_request(:post, /api\.deepseek\.com/).to_return(body: OPENAI_STYLE_BODY.to_json)

        assert_scored DeepseekProvider, 'deepseek-v4-flash', :deepseek
        assert_usage(input: 0, output: 0, total: 0)
      end

      def test_anthropic_without_usage
        stub_request(:post, /api\.anthropic\.com/)
          .to_return(body: { content: [{ type: 'tool_use', input: { score: 8 } }] }.to_json)

        assert_scored AnthropicProvider, 'claude-haiku-4-5', :anthropic
        assert_usage(input: 0, output: 0, total: 0)
      end

      def test_google_without_usage_metadata
        stub_google(nil)

        assert_scored GoogleProvider, 'gemini-3.5-flash-lite', :google
        assert_usage(input: 0, output: 0, total: 0)
      end

      def test_google_without_total_token_count_sums_the_parts
        stub_google({ promptTokenCount: 3, candidatesTokenCount: 2 })

        assert_scored GoogleProvider, 'gemini-3.5-flash-lite', :google
        assert_usage(input: 3, output: 2, total: 5)
      end

      private

      def stub_google(usage_metadata)
        body = { candidates: [{ content: { parts: [{ text: '{"score":8}' }] } }], usageMetadata: usage_metadata }
        stub_request(:post, /generativelanguage\.googleapis\.com/).to_return(body: body.compact.to_json)
      end

      def assert_scored(provider_class, model, provider_name)
        config = Configuration.new(
          llm: { model: },
          providers: { provider_name => { api_key: 'test_key' } },
          log: {
            output: ->(log) { @logs << log },
            file_path: File.join(@dir, 'active_genie.log'),
            fine_tune_file_path: File.join(@dir, 'fine_tune.log')
          }
        )

        assert_equal({ 'score' => 8 }, provider_class.new(config).function_calling(MESSAGES, FUNCTION))
      end

      def assert_usage(input:, output:, total:)
        usage = @logs.find { |log| log[:code] == :llm_usage }

        refute_nil usage, 'expected an :llm_usage entry'
        assert_equal [input, output, total], usage.values_at(:input_tokens, :output_tokens, :total_tokens)
      end
    end
  end
end

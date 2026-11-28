# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/anthropic_provider'

module ActiveGenie
  module Providers
    # Request and response rules of current Claude models (claude-haiku-5-5 and
    # every Claude 4.7+ model): non-default sampling parameters return a 400,
    # responses may start with thinking blocks, and requests can be refused.
    class AnthropicCurrentModelsTest < Minitest::Test
      URL = 'https://api.anthropic.com/v1/messages'
      FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: { type: 'object', properties: { score: { type: 'integer' } } }
      }.freeze
      MESSAGES = [{ role: 'user', content: 'Score this essay' }].freeze
      USAGE = { input_tokens: 10, output_tokens: 5 }.freeze
      TOOL_USE = { type: 'tool_use', id: 'toolu_1', name: 'score_function', input: { score: 8 } }.freeze

      def setup
        @dir = Dir.mktmpdir
      end

      def teardown
        super # webmock/minitest resets its request registry here
        FileUtils.remove_entry(@dir)
      end

      def test_never_sends_sampling_parameters_even_when_configured
        stub_anthropic(content: [TOOL_USE], stop_reason: 'tool_use')

        provider(llm: { temperature: 0.3 }).function_calling(MESSAGES, FUNCTION)

        assert_requested(:post, URL) do |req|
          body = JSON.parse(req.body)
          !body.key?('temperature') && !body.key?('top_p') && !body.key?('top_k')
        end
      end

      def test_sends_room_for_the_newer_tokenizer_by_default
        stub_anthropic(content: [TOOL_USE], stop_reason: 'tool_use')

        provider.function_calling(MESSAGES, FUNCTION)

        assert_requested(:post, URL) { |req| JSON.parse(req.body)['max_tokens'] == 16_000 }
      end

      def test_reads_the_tool_use_block_by_type_not_position
        thinking = { type: 'thinking', thinking: '', signature: 'sig' }
        stub_anthropic(content: [thinking, TOOL_USE], stop_reason: 'tool_use')

        assert_equal({ 'score' => 8 }, provider.function_calling(MESSAGES, FUNCTION))
      end

      def test_raises_a_refusal_error_with_the_category
        stub_anthropic(content: [], stop_reason: 'refusal',
                       stop_details: { type: 'refusal', category: 'cyber', explanation: 'declined' })

        error = assert_raises(ActiveGenie::RefusalError) { provider.function_calling(MESSAGES, FUNCTION) }

        assert_includes error.message, 'cyber'
      end

      def test_raises_when_the_answer_was_cut_off_by_max_tokens
        stub_anthropic(content: [TOOL_USE], stop_reason: 'max_tokens')

        error = assert_raises(ActiveGenie::TruncatedResponseError) { provider.function_calling(MESSAGES, FUNCTION) }

        assert_includes error.message, 'max_tokens'
        assert_includes error.message, 'Raise config.llm.max_tokens (it was 16000)'
      end

      private

      def stub_anthropic(**body)
        stub_request(:post, URL).to_return(body: { usage: USAGE, **body }.to_json)
      end

      def provider(llm: {})
        AnthropicProvider.new(
          Configuration.new(
            llm: { model: 'claude-haiku-5-5', **llm },
            providers: { anthropic: { api_key: 'test_key' } },
            log: {
              output: ->(_log) {},
              file_path: File.join(@dir, 'active_genie.log'),
              fine_tune_file_path: File.join(@dir, 'fine_tune.log')
            }
          )
        )
      end
    end
  end
end

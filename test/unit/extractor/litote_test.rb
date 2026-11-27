# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Extractor
    class LitoteTest < Minitest::Test
      OPENAI_CONFIG = {
        llm: { model: 'gpt-5.6-luna' },
        providers: { default: 'openai', openai: { api_key: 'openai_secret' } }
      }.freeze
      SCHEMA = { mood: { type: 'string', description: 'The mood of the message' } }.freeze
      OPENAI_URL = 'https://api.openai.com/v1/chat/completions'

      def test_a_litote_is_extracted_again_from_its_rephrasing
        stub_answers(
          { mood: 'negative', mood_explanation: 'Says bad.', message_litote: true,
            litote_rephrased: 'The weather is good today' },
          { mood: 'positive', mood_explanation: 'Good weather.' }
        )

        result = Litote.call("The weather isn't bad today", SCHEMA, config: OPENAI_CONFIG)

        assert_equal({ mood: 'positive' }, result.data)
        assert_equal 'Good weather.', result.reasoning
        assert_equal({ 'mood' => 'positive', 'mood_explanation' => 'Good weather.', 'message_litote' => true,
                       'litote_rephrased' => 'The weather is good today' }, result.metadata)
        assert_requested(:post, OPENAI_URL, times: 2)
        assert_requested(:post, OPENAI_URL) { |req| req.body.include?('The weather is good today') }
      end

      def test_a_plain_message_is_extracted_once_without_the_litote_fields
        stub_answers({ mood: 'positive', mood_explanation: 'Says great.', message_litote: false,
                       litote_rephrased: 'The weather is great today' })

        result = Litote.call('The weather is great today', SCHEMA, config: OPENAI_CONFIG)

        assert_equal({ mood: 'positive' }, result.data)
        assert_equal 'Says great.', result.reasoning
        assert_equal({ 'message_litote' => false, 'litote_rephrased' => 'The weather is great today' },
                     result.metadata.slice('message_litote', 'litote_rephrased'))
        assert_requested(:post, OPENAI_URL, times: 1)
      end

      private

      def stub_answers(*answers)
        responses = answers.map do |answer|
          tool_call = { function: { name: 'data_extractor', arguments: answer.to_json } }
          { status: 200, body: { choices: [{ message: { tool_calls: [tool_call] } }], usage: { total_tokens: 1 } }.to_json }
        end

        stub_request(:post, OPENAI_URL).to_return(*responses)
      end
    end
  end
end

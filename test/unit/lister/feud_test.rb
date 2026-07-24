# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Lister
    class FeudTest < Minitest::Test
      # Critical Path: Provider Requests & Unified Provider Integration
      def test_anthropic_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.anthropic.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-anthropic.json")
        )

        theme = 'Industries that are most likely to be affected by climate change'

        result = ActiveGenie::Lister.with_feud(
          theme,
          config: {
            llm: { provider: 'anthropic' },
            providers: { anthropic: { api_key: 'anthropic_secret' } }
          }
        )

        assert_requested(:post, 'https://api.anthropic.com/v1/messages') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert_includes request_body['system'], 'Emulate the game "Family Feud"'
          assert_includes messages, { 'role' => 'user', 'content' => "theme: #{theme}" }

          tool = request_body['tools'].first

          assert_equal 'feud_items_generator', tool['name']
        end

        expected_items = [
          'Agriculture',
          'Fishing',
          'Tourism',
          'Insurance',
          'Energy',
          'Real Estate',
          'Construction',
          'Forestry'
        ]

        assert_equal expected_items, result.data
        assert_equal 'These industries are critically vulnerable to environmental shifts, extreme weather events, and changing global conditions that directly impact their operations, resources, and economic stability.',
                     result.reasoning
        assert_instance_of Hash, result.metadata
        assert_equal expected_items, result.metadata['items']
      end

      def test_openai_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-openai.json")
        )

        theme = 'Industries that are most likely to be affected by climate change'

        result = ActiveGenie::Lister.with_feud(
          theme,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert(messages.any? { |m| m['role'] == 'system' && m['content'].include?('Emulate the game "Family Feud"') })
          assert(messages.any? { |m| m['role'] == 'system' && m['content'] == 'List 5 top items.' })
          assert_includes messages, { 'role' => 'user', 'content' => "theme: #{theme}" }

          tool = request_body['tools'].first

          assert_equal 'feud_items_generator', tool.dig('function', 'name')
        end

        expected_items = ['Agriculture / Farming', 'Insurance', 'Coastal Real Estate / Construction',
                          'Fishing / Aquaculture', 'Tourism / Hospitality']

        assert_equal expected_items, result.data
        assert_includes result.reasoning, 'Based on what average people would notice or worry about'
        assert_instance_of Hash, result.metadata
        assert_equal expected_items, result.metadata['items']
      end

      def test_google_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.google.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-google.json")
        )

        theme = 'Industries that are most likely to be affected by climate change'

        result = ActiveGenie::Lister.with_feud(
          theme,
          config: {
            llm: { provider: 'google' },
            providers: { google: { api_key: 'google_secret' } }
          }
        )

        assert_requested(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent}) do |req|
          request_body = JSON.parse(req.body)
          contents = request_body['contents']

          assert(contents.any? { |c| c['parts'].first['text'].include?('Emulate the game "Family Feud"') })
          assert(contents.any? { |c| c['parts'].first['text'] == 'List 5 top items.' })
          assert(contents.any? { |c| c['parts'].first['text'] == "theme: #{theme}" })
        end

        expected_items = ['Agriculture/Farming', 'Tourism', 'Insurance', 'Fishing/Seafood', 'Real Estate']

        assert_equal expected_items, result.data
        assert_includes result.reasoning, 'These industries were chosen because their operations'
        assert_instance_of Hash, result.metadata
      end

      def test_deepseek_request
        stub_request(:post, /#{ActiveGenie.configuration.providers.deepseek.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-deepseek.json")
        )

        theme = 'Industries that are most likely to be affected by climate change'

        result = ActiveGenie::Lister.with_feud(
          theme,
          config: {
            llm: { provider: 'deepseek' },
            providers: { deepseek: { api_key: 'deepseek_secret' } }
          }
        )

        assert_requested(:post, 'https://api.deepseek.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert(messages.any? { |m| m['role'] == 'system' && m['content'].include?('Emulate the game "Family Feud"') })
          assert(messages.any? { |m| m['role'] == 'system' && m['content'] == 'List 5 top items.' })
          assert_includes messages, { 'role' => 'user', 'content' => "theme: #{theme}" }

          tool = request_body['tools'].first

          assert_equal 'feud_items_generator', tool.dig('function', 'name')
        end

        expected_items = ['Agriculture', 'Insurance', 'Tourism', 'Energy', 'Real Estate']

        assert_equal expected_items, result.data
        assert_includes result.reasoning, 'These industries were chosen because they are directly exposed'
        assert_instance_of Hash, result.metadata
      end

      # Critical Path: Dynamic Configuration
      def test_respects_custom_number_of_items_config
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-openai.json")
        )

        theme = 'Top programming languages'

        result = Feud.call(
          theme,
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } },
            lister: { number_of_items: 10 }
          }
        )

        assert_instance_of ActiveGenie::Result, result

        # Assert custom number_of_items (10) was injected into the system prompt message
        assert_requested(:post, 'https://api.openai.com/v1/chat/completions') do |req|
          request_body = JSON.parse(req.body)
          messages = request_body['messages']

          assert(messages.any? { |m| m['role'] == 'system' && m['content'] == 'List 10 top items.' })
        end
      end

      # Critical Path: Fallback Behavior
      def test_fallback_when_items_field_missing
        missing_items_json = {
          choices: [
            {
              message: {
                tool_calls: [
                  {
                    function: {
                      name: 'feud_items_generator',
                      arguments: JSON.generate({
                        'why_these_items' => 'Items could not be determined for this theme'
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
          body: missing_items_json
        )

        result = Feud.call(
          'Abstract concept',
          config: {
            llm: { provider: 'openai' },
            providers: { openai: { api_key: 'openai_secret' } }
          }
        )

        assert_equal [], result.data
        assert_equal 'Items could not be determined for this theme', result.reasoning
      end

      # Critical Path: Module Configuration & Delegation
      def test_module_config_recommended_model
        feud_instance = Feud.new('Theme')
        config = feud_instance.send(:module_config)

        assert_equal({ llm: { recommended_model: 'claude-haiku-4-5' } }, config)
      end

      def test_lister_module_delegation_methods
        stub_request(:post, /#{ActiveGenie.configuration.providers.openai.api_url}.*$/).to_return(
          status: 200,
          body: File.read("#{__dir__}/../fixtures/lister-openai.json")
        )

        config = {
          llm: { provider: 'openai' },
          providers: { openai: { api_key: 'openai_secret' } }
        }

        theme = 'Industries that are most likely to be affected by climate change'

        res1 = ActiveGenie::Lister.call(theme, config:)
        res2 = ActiveGenie::Lister.with_feud(theme, config:)
        res3 = Feud.call(theme, config:)

        assert_equal res1.data, res2.data
        assert_equal res2.data, res3.data
        assert_equal res1.reasoning, res3.reasoning
      end
    end
  end
end


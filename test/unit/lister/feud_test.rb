# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  module Lister
    class FeudTest < Minitest::Test
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
        assert_equal 'These industries are critically vulnerable to environmental shifts, extreme weather events, and changing global conditions that directly impact their operations, resources, and economic stability.', result.reasoning
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
          assert_includes messages, { 'role' => 'user', 'content' => "theme: #{theme}" }

          tool = request_body['tools'].first
          assert_equal 'feud_items_generator', tool.dig('function', 'name')
        end

        expected_items = ["Agriculture / Farming", "Insurance", "Coastal Real Estate / Construction", "Fishing / Aquaculture", "Tourism / Hospitality"]
        assert_equal expected_items, result.data
        assert_equal 'Based on what average people would notice or worry about: impacts on food supply and crops are widely cited; insurance is a common everyday concern because of storm losses and rising premiums; coastal real estate and construction are visible from sea-level rise and storm damage; fishing and aquaculture are affected by ocean warming and acidification; and tourism/hospitality (beach resorts, ski areas) are often mentioned when discussing climate impacts on livelihoods and local economies.', result.reasoning
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
          assert(contents.any? { |c| c['parts'].first['text'] == "theme: #{theme}" })
        end

        expected_items = ["Agriculture/Farming", "Tourism", "Insurance", "Fishing/Seafood", "Real Estate"]
        assert_equal expected_items, result.data
        assert_equal 'These industries were chosen because their operations, assets, and customer bases are directly and visibly vulnerable to the physical impacts of climate change (e.g., extreme weather, sea-level rise, resource scarcity) or to the policy and market shifts driven by climate change concerns. They represent sectors where the average person would most readily identify a clear and significant link to climate change effects, often experiencing these impacts personally or through news reports.', result.reasoning
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
          assert_includes messages, { 'role' => 'user', 'content' => "theme: #{theme}" }

          tool = request_body['tools'].first
          assert_equal 'feud_items_generator', tool.dig('function', 'name')
        end

        expected_items = ["Agriculture", "Insurance", "Tourism", "Energy", "Real Estate"]
        assert_equal expected_items, result.data
        assert_equal 'These industries were chosen because they are directly exposed to climate-related risks like extreme weather events, sea level rise, temperature changes, and regulatory shifts. Agriculture is most vulnerable due to crop failures from droughts and floods. Insurance faces massive claims from climate disasters. Tourism depends on stable weather patterns and coastal infrastructure. Energy production is affected by water scarcity and extreme weather. Real estate in coastal areas faces flooding risks that could devalue properties.', result.reasoning
      end
    end
  end
end
# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/unified_provider'

module ActiveGenie
  module Config
    class ProvidersConfigTest < Minitest::Test
      LISTER_ANSWER = { items: ['a'], why_these_items: 'x' }.to_json

      # An OpenAI-compatible gateway: same API, different default URL.
      class GatewayConfig < Providers::OpenaiConfig
        def api_url
          @api_url || 'https://gateway.example.com/v1'
        end
      end

      def setup
        @dir = Dir.mktmpdir
      end

      def teardown
        super # webmock/minitest resets its request registry here
        FileUtils.remove_entry(@dir)
      end

      def test_add_replaces_a_builtin_provider_config_and_calls_use_it
        stub_openai_style('https://gateway.example.com/v1/chat/completions')
        config = build_config(openai: { api_key: 'k' })

        config.providers.add(:openai, GatewayConfig)
        config.providers.openai.api_key = 'gateway-key'
        ActiveGenie::Lister.call('theme', config:)

        assert_requested(:post, 'https://gateway.example.com/v1/chat/completions',
                         headers: { 'Authorization' => 'Bearer gateway-key' })
      end

      def test_add_accepts_a_config_instance_and_a_string_name
        config = build_config
        gateway = GatewayConfig.new(api_key: 'k')

        config.providers.add('openai', gateway)

        assert_same gateway, config.providers.openai
      end

      def test_add_rejects_providers_activegenie_cannot_call
        error = assert_raises(ActiveGenie::InvalidProviderError) { build_config.providers.add(:mistral, GatewayConfig) }

        assert_includes error.message, 'Unknown provider "mistral". ActiveGenie can call: openai'
      end

      def test_removed_provider_is_never_used_by_module_calls
        stub_openai_style('https://api.openai.com/v1/chat/completions')
        config = build_config(openai: { api_key: 'k' }, deepseek: { api_key: 'k' })

        config.providers.remove(:deepseek)
        # Extractor falls back to deepseek-flash when DeepSeek has credentials.
        ActiveGenie::Extractor.data('Total: $4', { total: { type: 'number' } }, config:)

        assert_requested(:post, /api\.openai\.com/)
        assert_not_requested(:post, /api\.deepseek\.com/)
        refute_includes config.providers.valid.keys, :deepseek
      end

      def test_remove_accepts_names_as_strings_and_lists
        config = build_config

        config.providers.remove(%w[google anthropic])

        assert_equal %i[openai deepseek], config.providers.all.keys
      end

      def test_builtin_providers_match_the_providers_activegenie_can_call
        callable = ActiveGenie::Providers::UnifiedProvider.singleton_class::PROVIDER_NAME_TO_PROVIDER.keys

        assert_equal callable.sort, ProvidersConfig::BUILT_IN.keys.sort
      end

      private

      def stub_openai_style(url)
        body = { choices: [{ message: { tool_calls: [{ function: { arguments: LISTER_ANSWER } }] } }],
                 usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 } }
        stub_request(:post, url).to_return(body: body.to_json)
      end

      def build_config(providers = {})
        ActiveGenie::Configuration.new(
          providers:,
          log: {
            output: ->(_log) {},
            file_path: File.join(@dir, 'active_genie.log'),
            fine_tune_file_path: File.join(@dir, 'fine_tune.log')
          }
        )
      end
    end
  end
end

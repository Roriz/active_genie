# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/unified_provider'

module ActiveGenie
  module Providers
    class UnifiedProviderTest < Minitest::Test
      EXAMPLE_FUNCTION = {
        name: 'test_function',
        description: 'Test function',
        parameters: {
          type: 'object',
          properties: {
            test_field: { type: 'string' },
            number_field: { type: 'integer' }
          }
        }
      }.freeze
      EXAMPLE_MESSAGES = [{ role: 'user', content: 'Test message' }].freeze

      def test_choose_openai_by_provider_name
        config = Configuration.new({ llm: { provider_name: 'openai' }, providers: { openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        ActiveGenie::Providers::OpenaiProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify
      end

      def test_unknown_provider_raises_invalid_provider
        config = Configuration.new({ llm: { model: 'command-r' }, providers: { default: 'cohere' } })

        error = assert_raises(ActiveGenie::InvalidProviderError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_includes error.message, 'Unknown provider "cohere"'
      end

      def test_unknown_default_provider_raises_even_when_another_provider_has_a_key
        config = Configuration.new({ providers: { default: 'cohere', openai: { api_key: 'secret' } } })

        assert_raises(ActiveGenie::InvalidProviderError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end
      end

      # It used to fall back to any provider with a key without a word.
      def test_a_default_provider_without_an_api_key_raises
        config = Configuration.new({ providers: { default: 'anthropic', openai: { api_key: 'secret' } } })

        error = assert_raises(ActiveGenie::ProviderWithoutApiKeyError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_includes error.message, 'The default provider "anthropic" has no API key'
        assert_includes error.message, 'Set the ANTHROPIC_API_KEY environment variable'
        assert_includes error.message, "config.providers.anthropic.api_key = ENV.fetch('ANTHROPIC_API_KEY')"
        assert_includes error.message, 'a provider that has a key (openai)'
      end

      # It used to say the removed provider had no API key, though its key was set.
      def test_a_default_provider_that_was_removed_says_so
        config = Configuration.new({ providers: { default: 'anthropic', anthropic: { api_key: 'secret' },
                                                  openai: { api_key: 'secret' } } })
        config.providers.remove(:anthropic)

        error = assert_raises(ActiveGenie::DefaultProviderRemovedError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_includes error.message, 'The default provider "anthropic" was removed from config.providers'
        assert_includes error.message, 'drop config.providers.remove(:anthropic)'
        assert_includes error.message, "still configured\n  with a key (openai)"
      end

      def test_a_default_provider_from_provider_name_without_an_api_key_raises
        previous = ENV.fetch('PROVIDER_NAME', nil)
        ENV['PROVIDER_NAME'] = 'google'
        config = Configuration.new({ providers: { openai: { api_key: 'secret' } } })

        error = assert_raises(ActiveGenie::ProviderWithoutApiKeyError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_includes error.message, 'GEMINI_API_KEY'
      ensure
        ENV['PROVIDER_NAME'] = previous
      end

      def test_a_per_call_default_provider_without_an_api_key_raises
        assert_raises(ActiveGenie::ProviderWithoutApiKeyError) do
          ActiveGenie::Scorer.call('text', 'criteria',
                                   config: { providers: { default: 'deepseek', openai: { api_key: 'secret' } } })
        end
      end

      # Only the user's default raises: Comparator recommends a Claude model, Anthropic has no key here.
      def test_a_recommended_model_whose_provider_has_no_key_falls_back_to_one_that_has
        config = Configuration.new({ llm: { recommended_model: 'claude-haiku-5-5' },
                                     providers: { openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::OpenaiProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gpt-5.6-luna', received_config.llm.model
      end

      def test_no_credentialed_provider_raises_without_available_provider
        assert_raises(ActiveGenie::WithoutAvailableProviderError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION,
                                                                   config: Configuration.new({}))
        end
      end

      # It used to fall back to another provider's default model without a word.
      def test_a_model_no_credentialed_provider_runs_raises_invalid_model
        config = Configuration.new({ llm: { model: 'command-r' }, providers: { openai: { api_key: 'secret' } } })

        error = assert_raises(ActiveGenie::InvalidModelError) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_includes error.message, '"command-r" (providers with a key: openai)'
      end

      def test_choose_openai_by_model_name
        config = Configuration.new({ llm: { model: 'gpt-5' }, providers: { openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::OpenaiProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gpt-5', received_config.llm.model
      end

      def test_choose_openai_by_available_provider
        config = Configuration.new({ providers: { openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::OpenaiProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gpt-5.6-luna', received_config.llm.model
      end

      def test_choose_openai_by_default_provider
        config = Configuration.new({ providers: { default: 'openai', google: { api_key: 'secret' },
                                                  openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::OpenaiProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gpt-5.6-luna', received_config.llm.model
      end

      def test_choose_openai_by_recommended_model
        config = Configuration.new({
                                     llm: { recommended_model: 'gpt-9' },
                                     providers: { openai: { api_key: 'secret' } }
                                   })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::OpenaiProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gpt-9', received_config.llm.model
      end

      def test_recommended_model_without_valid_provider
        config = Configuration.new({
                                     llm: { recommended_model: 'gpt-9' },
                                     providers: { google: { api_key: 'secret' } }
                                   })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::GoogleProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gemini-3.8-flash', received_config.llm.model
      end

      def test_google_function_calling
        config = Configuration.new({ llm: { provider_name: 'google' }, providers: { google: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        ActiveGenie::Providers::GoogleProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify
      end

      def test_choose_google_by_default_provider
        config = Configuration.new({ providers: { default: 'google', google: { api_key: 'secret' },
                                                  openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::GoogleProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gemini-3.8-flash', received_config.llm.model
      end

      def test_choose_google_by_available_provider
        config = Configuration.new({ providers: { google: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        received_config = nil
        ActiveGenie::Providers::GoogleProvider.stub(:new, lambda { |c|
          received_config = c
          mock_provider_instance
        }) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify

        assert_equal 'gemini-3.8-flash', received_config.llm.model
      end

      def test_deepseek_function_calling
        config = Configuration.new({ llm: { provider_name: 'deepseek' },
                                     providers: { deepseek: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        ActiveGenie::Providers::DeepseekProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify
      end

      def test_anthropic_function_calling
        config = Configuration.new({ llm: { provider_name: 'anthropic' },
                                     providers: { anthropic: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'test_field' => 'value' },
                                      [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        ActiveGenie::Providers::AnthropicProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        mock_provider_instance.verify
      end

      # Test response normalization
      def test_response_normalization
        config = Configuration.new({ llm: { provider_name: 'openai' }, providers: { openai: { api_key: 'secret' } } })

        mock_provider_instance = Minitest::Mock.new
        mock_response = {
          field_null: 'null',
          field_none: 'none',
          field_undefined: 'undefined',
          field_empty: '',
          field_unknown: 'unknown',
          field_unknown_brackets: '<unknown>',
          field_valid: 'valid_value'
        }
        mock_provider_instance.expect(:function_calling, mock_response, [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        ActiveGenie::Providers::OpenaiProvider.stub(:new, mock_provider_instance) do
          result = ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)

          assert_nil result[:field_null]
          assert_nil result[:field_none]
          assert_nil result[:field_undefined]
          assert_nil result[:field_empty]
          assert_nil result[:field_unknown]
          assert_nil result[:field_unknown_brackets]
          assert_equal 'valid_value', result[:field_valid]
        end
      end

      def test_response_normalization_of_placeholders_wrapped_in_punctuation
        config = Configuration.new({ llm: { provider_name: 'openai' }, providers: { openai: { api_key: 'secret' } } })
        mock_provider_instance = Minitest::Mock.new
        mock_response = { 'colon' => ':null', 'quoted' => '"None"', 'parens' => '(unknown)', 'dot' => 'null.',
                          'spaced' => '  ', 'phrase' => 'None of the above', 'dash' => '-' }
        mock_provider_instance.expect(:function_calling, mock_response, [EXAMPLE_MESSAGES, EXAMPLE_FUNCTION])

        result = ActiveGenie::Providers::OpenaiProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, config:)
        end

        assert_equal({ 'colon' => nil, 'quoted' => nil, 'parens' => nil, 'dot' => nil, 'spaced' => nil,
                       'phrase' => 'None of the above', 'dash' => '-' }, result)
      end

      def test_response_normalization_keeps_a_placeholder_the_schema_declares_as_an_enum_value
        config = Configuration.new({ llm: { provider_name: 'openai' }, providers: { openai: { api_key: 'secret' } } })
        function = { name: 'triage', description: 'Triage a patient note', parameters: {
          type: 'object',
          properties: { allergy: { type: 'string', enum: %w[none mild severe] },
                        'smoker' => { 'type' => %w[string null], 'enum' => ['unknown', 'yes', 'no', nil] },
                        notes: { type: 'string' } }
        } }
        mock_provider_instance = Minitest::Mock.new
        mock_provider_instance.expect(:function_calling, { 'allergy' => 'none', 'smoker' => 'unknown', 'notes' => 'none' },
                                      [EXAMPLE_MESSAGES, function])

        result = ActiveGenie::Providers::OpenaiProvider.stub(:new, mock_provider_instance) do
          ActiveGenie::Providers::UnifiedProvider.function_calling(EXAMPLE_MESSAGES, function, config:)
        end

        assert_equal({ 'allergy' => 'none', 'smoker' => 'unknown', 'notes' => nil }, result)
      end
    end
  end
end

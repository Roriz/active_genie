# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/base_provider'

module ActiveGenie
  module Providers
    class BaseProviderTest < Minitest::Test
      URL = 'https://api.example.com/v1/generate'

      # Minimal concrete provider: one retried POST, like the real providers do.
      class EchoProvider < BaseProvider
        def generate
          retry_with_backoff { post(URL, { prompt: 'hi' }) }
        end
      end

      def setup
        @logs = []
        config = Configuration.new({
                                     llm: { max_retries: 2, retry_delay: 0 },
                                     log: { output: ->(log) { @logs << log } }
                                   })
        @provider = EchoProvider.new(config)
      end

      def test_retries_server_errors_until_success
        stub_request(:post, URL).to_return({ status: 500, body: 'boom' }, { status: 200, body: '{"ok":true}' })

        assert_equal({ 'ok' => true }, @provider.generate)
        assert_requested(:post, URL, times: 2)
        assert_equal([1], @logs.select { |log| log[:code] == :retry_attempt }.map { |log| log[:attempt] })
      end

      def test_retries_rate_limits_until_success
        stub_request(:post, URL).to_return({ status: 429, body: 'slow down' }, { status: 200, body: '{"ok":true}' })

        assert_equal({ 'ok' => true }, @provider.generate)
        assert_requested(:post, URL, times: 2)
      end

      def test_gives_up_after_max_retries_with_a_provider_unknown_error
        stub_request(:post, URL).to_return(status: 503, body: 'unavailable')

        error = assert_raises(BaseProvider::ProviderUnknownError) { @provider.generate }

        assert_kind_of BaseProvider::ProviderTransientError, error
        assert_equal 'Unexpected response: 503 - unavailable', error.message
        # one initial attempt plus max_retries (2) retries
        assert_requested(:post, URL, times: 3)
      end

      def test_does_not_retry_client_errors
        stub_request(:post, URL).to_return(status: 400, body: 'bad request')

        error = assert_raises(BaseProvider::ProviderUnknownError) { @provider.generate }

        refute_kind_of BaseProvider::ProviderTransientError, error
        assert_requested(:post, URL, times: 1)
        assert_empty(@logs.select { |log| log[:code] == :retry_attempt })
      end
    end
  end
end

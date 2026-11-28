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

        error = assert_raises(ActiveGenie::ProviderUnknownError) { @provider.generate }

        assert_kind_of ActiveGenie::ProviderTransientError, error
        assert_equal 'AG-E102', error.code
        assert_includes error.message, 'answered HTTP 503 for model nil after 2 retries: unavailable'
        # one initial attempt plus max_retries (2) retries
        assert_requested(:post, URL, times: 3)
      end

      def test_does_not_retry_client_errors
        stub_request(:post, URL).to_return(status: 400, body: 'bad request')

        error = assert_raises(ActiveGenie::ProviderUnknownError) { @provider.generate }

        refute_kind_of ActiveGenie::ProviderTransientError, error
        assert_includes error.message, 'HTTP 400'
        assert_includes error.message, 'bad request'
        assert_requested(:post, URL, times: 1)
        assert_empty(@logs.select { |log| log[:code] == :retry_attempt })
      end

      def test_names_the_api_key_when_the_provider_refuses_it
        stub_request(:post, URL).to_return(status: 401, body: '{"error":"invalid x-api-key"}')

        error = assert_raises(ActiveGenie::ProviderUnknownError) { @provider.generate }

        assert_includes error.message, 'The provider refused the API key'
      end

      def test_gives_up_on_network_errors_with_a_provider_connection_error
        stub_request(:post, URL).to_raise(Net::OpenTimeout)

        error = assert_raises(ActiveGenie::ProviderConnectionError) { @provider.generate }

        assert_includes error.message, 'after 3 attempts: Net::OpenTimeout'
        assert_kind_of Net::OpenTimeout, error.cause
        assert_requested(:post, URL, times: 3)
      end

      def test_a_success_body_that_is_not_json_raises_invalid_response
        stub_request(:post, URL).to_return(status: 200, body: '<html>gateway</html>')

        error = assert_raises(ActiveGenie::InvalidResponseError) { @provider.generate }

        assert_includes error.message, 'HTTP 200 with a body that is not JSON'
        assert_requested(:post, URL, times: 1)
      end
    end
  end
end

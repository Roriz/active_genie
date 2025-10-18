# frozen_string_literal: true

require 'net/http'
require_relative '../errors/provider_server_error'

module ActiveGenie
  module Providers
    class BaseProvider
      class ProviderUnknownError < StandardError; end

      DEFAULT_HEADERS = {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'User-Agent': "ActiveGenie/#{ActiveGenie::VERSION}"
      }.freeze

      DEFAULT_TIMEOUT = 60 # seconds
      DEFAULT_OPEN_TIMEOUT = 10 # seconds
      DEFAULT_MAX_RETRIES = 3
      DEFAULT_RETRY_DELAY = 1 # seconds

      def initialize(config)
        @config = config
      end

      # Make a GET request to the specified endpoint
      #
      # @param endpoint [String] The API endpoint to call
      # @param headers [Hash] Additional headers to include in the request
      # @param params [Hash] Query parameters for the request
      # @return [Hash, nil] The parsed JSON response or nil if empty
      def get(endpoint, params: {}, headers: {})
        uri = build_uri(endpoint, params)
        request = Net::HTTP::Get.new(uri)
        apply_headers(request, headers)
        execute_request(uri, request)
      end

      # Make a POST request to the specified endpoint
      #
      # @param endpoint [String] The API endpoint to call
      # @param payload [Hash] The request body to send
      # @param headers [Hash] Additional headers to include in the request
      # @return [Hash, nil] The parsed JSON response or nil if empty
      def post(endpoint, payload, params: {}, headers: {})
        uri = build_uri(endpoint, params)
        request = Net::HTTP::Post.new(uri)
        request.body = payload.to_json
        apply_headers(request, headers)
        execute_request(uri, request)
      end

      # Make a PUT request to the specified endpoint
      #
      # @param endpoint [String] The API endpoint to call
      # @param payload [Hash] The request body to send
      # @param headers [Hash] Additional headers to include in the request
      # @return [Hash, nil] The parsed JSON response or nil if empty
      def put(endpoint, payload, headers: {})
        uri = build_uri(endpoint)
        request = Net::HTTP::Put.new(uri)
        request.body = payload.to_json
        apply_headers(request, headers)
        execute_request(uri, request)
      end

      # Make a DELETE request to the specified endpoint
      #
      # @param endpoint [String] The API endpoint to call
      # @param headers [Hash] Additional headers to include in the request
      # @param params [Hash] Query parameters for the request
      # @return [Hash, nil] The parsed JSON response or nil if empty
      def delete(endpoint, headers: {}, params: {})
        uri = build_uri(endpoint, params)
        request = Net::HTTP::Delete.new(uri)
        apply_headers(request, headers)
        execute_request(uri, request)
      end

      protected

      def execute_request(uri, request)
        start_time = Time.now

        response = http_request(request, uri)

        raise ProviderUnknownError, "Unexpected response: #{response.code} - #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        parsed_response = parse_response(response)

        log_request_details(uri:, request:, response:, start_time:, parsed_response:)

        parsed_response
      end

      # Create and configure an HTTP client
      #
      # @param uri [URI] The URI for the request
      # @return [Net::HTTP] Configured HTTP client
      def http_request(request, uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.read_timeout = @config.llm.read_timeout || DEFAULT_TIMEOUT
        http.open_timeout = @config.llm.open_timeout || DEFAULT_OPEN_TIMEOUT

        http.request(request)
      end

      # Apply headers to the request
      #
      # @param request [Net::HTTP::Request] The request object
      # @param headers [Hash] Additional headers to include
      def apply_headers(request, headers)
        DEFAULT_HEADERS.each do |key, value|
          request[key] = value
        end

        headers.each do |key, value|
          request[key.to_s] = value
        end
      end

      # Build a URI for the request
      #
      # @param endpoint [String] The API endpoint
      # @param params [Hash] Query parameters
      # @return [URI] The constructed URI
      def build_uri(endpoint, params = {})
        uri = endpoint.is_a?(URI) ? endpoint : URI(endpoint)

        uri.query = URI.encode_www_form(params) unless params.empty?

        uri
      end

      # Parse the response body
      #
      # @param response [Net::HTTPResponse] The HTTP response
      # @return [Hash, nil] Parsed JSON or nil if empty
      def parse_response(response)
        return nil if response.body.nil? || response.body.empty?

        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise ProviderUnknownError, "Failed to parse JSON response: #{e.message}"
        end
      end

      # Log request details if logging is enabled
      #
      # @param details [Hash] Request and response details
      def log_request_details(uri:, request:, response:, start_time:, parsed_response:)
        ActiveGenie.logger.call(
          {
            code: :http_request,
            uri: uri.to_s,
            method: request.method,
            status: response.code,
            duration: Time.now - start_time,
            response_size: parsed_response.to_s.bytesize
          }, config: @config
        )
      end

      # FIXME: split the retry_with_backoff method into a separate class
      # rubocop:disable Metrics/MethodLength
      def retry_with_backoff
        retries = 0

        begin
          yield
        rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, ActiveGenie::ProviderServerError, JSON::ParserError => e
          raise if retries > max_retries

          sleep_time = retry_delay * (2**retries)
          retries += 1

          ActiveGenie.logger.call(
            {
              code: :retry_attempt,
              attempt: retries,
              max_retries:,
              next_retry_in_seconds: sleep_time,
              error: e.message
            }, config: @config
          )

          sleep(sleep_time)
          retry
        end
      end
      # rubocop:enable Metrics/MethodLength

      def max_retries
        @config.llm.max_retries || DEFAULT_MAX_RETRIES
      end

      def retry_delay
        @config.llm.retry_delay || DEFAULT_RETRY_DELAY
      end
    end
  end
end

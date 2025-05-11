# frozen_string_literal: true

module ActiveGenie
  module Clients
    class BaseClient
      class ClientError < StandardError; end
      class RateLimitError < ClientError; end
      class TimeoutError < ClientError; end
      class NetworkError < ClientError; end

      DEFAULT_HEADERS = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ActiveGenie/1.0'
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
        execute_request(uri, request, headers)
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
        execute_request(uri, request, headers)
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
        execute_request(uri, request, headers)
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
        execute_request(uri, request, headers)
      end

      protected

      # Execute a request with retry logic and proper error handling
      #
      # @param uri [URI] The URI for the request
      # @param request [Net::HTTP::Request] The request object
      # @param headers [Hash] Additional headers to include
      # @return [Hash, nil] The parsed JSON response or nil if empty
      def execute_request(uri, request, headers)
        start_time = Time.now

        # Apply headers
        apply_headers(request, headers)

        # Apply retry logic
        retry_with_backoff do
          http = create_http_client(uri)

          begin
            response = http.request(request)

            # Handle common HTTP errors
            case response
            when Net::HTTPSuccess
              parsed_response = parse_response(response)

              # Log request details if logging is enabled
              log_request_details(
                uri: uri,
                method: request.method,
                status: response.code,
                duration: Time.now - start_time,
                response: parsed_response
              )

              parsed_response
            when Net::HTTPTooManyRequests
              raise RateLimitError, "Rate limit exceeded: #{response.body}"
            when Net::HTTPClientError, Net::HTTPServerError
              raise ClientError, "HTTP Error #{response.code}: #{response.body}"
            else
              raise ClientError, "Unexpected response: #{response.code} - #{response.body}"
            end
          rescue Timeout::Error, Errno::ETIMEDOUT
            raise TimeoutError, "Request to #{uri} timed out"
          rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, SocketError => e
            raise NetworkError, "Network error: #{e.message}"
          end
        end
      end

      # Create and configure an HTTP client
      #
      # @param uri [URI] The URI for the request
      # @return [Net::HTTP] Configured HTTP client
      def create_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.read_timeout = @config.llm.read_timeout || DEFAULT_TIMEOUT
        http.open_timeout = @config.llm.open_timeout || DEFAULT_OPEN_TIMEOUT
        http
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
          raise ClientError, "Failed to parse JSON response: #{e.message}"
        end
      end

      # Log request details if logging is enabled
      #
      # @param details [Hash] Request and response details
      def log_request_details(details)
        ActiveGenie::Logger.call({
                                    code: :http_request,
                                    uri: details[:uri].to_s,
                                    method: details[:method],
                                    status: details[:status],
                                    duration: details[:duration],
                                    response_size: details[:response].to_s.bytesize
                                  })
      end

      # Retry a block with exponential backoff
      #
      # @yield The block to retry
      # @return [Object] The result of the block
      def retry_with_backoff
        max_retries = @config.llm.max_retries || DEFAULT_MAX_RETRIES
        retry_delay = @config.llm.retry_delay || DEFAULT_RETRY_DELAY

        retries = 0

        begin
          yield
        rescue RateLimitError, NetworkError => e
          raise unless retries < max_retries

          sleep_time = retry_delay * (2**retries)
          retries += 1

          if defined?(ActiveGenie::Logger)
            ActiveGenie::Logger.call({
                                        code: :retry_attempt,
                                        attempt: retries,
                                        max_retries: max_retries,
                                        delay: sleep_time,
                                        error: e.message
                                      })
          end

          sleep(sleep_time)
          retry
        end
      end
    end
  end
end

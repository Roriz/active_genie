require 'json'
require 'net/http'
require 'uri'
require_relative './helpers/retry'

module ActiveGenie
  module Clients
    # Client for interacting with the Google Generative Language API.
    class GoogleClient
      class GoogleError < StandardError; end
      class RateLimitError < GoogleError; end

      API_VERSION_PATH = '/v1beta/models'.freeze
      DEFAULT_HEADERS = {
        'Content-Type': 'application/json',
      }.freeze

      def initialize(config)
        @app_config = config
      end

      # Requests structured JSON output from the Google Generative Language model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user' or 'model') and :content (String).
      #   Google Generative Language uses 'user' and 'model' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @param model_tier [Symbol, nil] A symbolic representation of the model quality/size tier.
      # @param config [Hash] Optional configuration overrides:
      #   - :api_key [String] Override the default API key.
      #   - :model [String] Override the model name directly.
      #   - :max_retries [Integer] Max retries for the request.
      #   - :retry_delay [Integer] Initial delay for retries.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function, model_tier: nil, config: {})
        model = config[:runtime][:model] || @app_config.tier_to_model(model_tier)
        api_key = config[:runtime][:api_key] || @app_config.api_key

        contents = convert_messages_to_contents(messages, function)
        contents << output_as_json_schema(function)

        payload = {
          contents: contents,
          generationConfig: {
            response_mime_type: "application/json",
            temperature: 0.1
          }
        }

        url = URI("#{@app_config.api_url}#{API_VERSION_PATH}/#{model}:generateContent?key=#{api_key}")

        retry_with_backoff(config:) do
          response = request(url, payload, model, config:)

          json_string = response&.dig('candidates', 0, 'content', 'parts', 0, 'text')
  
          return nil if json_string.nil? || json_string.empty?
  
          parsed_response = JSON.parse(json_string)
  
          ActiveGenie::Logger.trace({ step: :function_calling, payload:, parsed_response: })
  
          parsed_response
        end
      end

      private

      def request(url, payload, model, config:)
        start_time = Time.now

        retry_with_backoff(config:) do
          response = Net::HTTP.post(url, payload.to_json, DEFAULT_HEADERS)

          case response
          when Net::HTTPSuccess
            return nil if response.body.nil? || response.body.empty?

            parsed_body = JSON.parse(response.body)

            usage_metadata = parsed_body['usageMetadata'] || {}
            prompt_tokens = usage_metadata['promptTokenCount'] || 0
            candidates_tokens = usage_metadata['candidatesTokenCount'] || 0
            total_tokens = usage_metadata['totalTokenCount'] || (prompt_tokens + candidates_tokens)

            ActiveGenie::Logger.trace({
              step: :llm_stats,
              input_tokens: prompt_tokens,
              output_tokens: candidates_tokens,
              total_tokens: total_tokens,
              model: model,
              duration: Time.now - start_time,
              usage: usage_metadata # Log the whole usage block
            })

            parsed_body

          when Net::HTTPTooManyRequests
            # Rate Limit Error
            raise RateLimitError, "Google API rate limit exceeded (HTTP 429): #{response.body}"

          else
            # Other Errors
            raise GoogleError, "Google API error (HTTP #{response.code}): #{response.body}"
          end
        end
      rescue JSON::ParserError => e
          raise GoogleError, "Failed to parse Google API response body: #{e.message} - Body: #{response&.body}"
      end

      ROLE_TO_GOOGLE_ROLE = {
        user: 'user',
        assistant: 'model',
      }.freeze

      # Converts standard message format to Google's 'contents' format
      # and injects JSON schema instructions.
      # @param messages [Array<Hash>] Array of { role: 'user'/'assistant'/'system', content: '...' }
      # @param function_schema [Hash] The JSON schema for the desired output.
      # @return [Array<Hash>] Array formatted for Google's 'contents' field.
      def convert_messages_to_contents(messages, function_schema)
        messages.map do |message|
          {
            role: ROLE_TO_GOOGLE_ROLE[message[:role].to_sym] || 'user',
            parts: [{ text: message[:content] }]
          }
        end
      end

      def output_as_json_schema(function_schema)
        json_instruction = <<~PROMPT
          Generate a JSON object that strictly adheres to the following JSON schema:

          ```json
          #{JSON.pretty_generate(function_schema)}
          ```

          IMPORTANT: Only output the raw JSON object. Do not include any other text, explanations, or markdown formatting like ```json ... ``` wrappers around the final output.
        PROMPT

        {
          role: 'user',
          parts: [{ text: json_instruction }]
        }
      end
    end
  end
end

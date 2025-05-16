
require_relative './helpers/minitest_with_stub_requests'

module ActiveGenie
  class DataExtractorTest < MinitestWithStubRequests
    def test_openai_request
      text = "Input Text"
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::DataExtractor.call(text, schema, config: { provider: 'openai' })

      assert_requested(:post, "https://api.openai.com/v1/chat/completions") do |req|
        request_body = JSON.parse(req.body)

        assert_includes request_body['messages'], { 'role' => 'user', 'content' => text }

        function_properties = request_body.dig('tools', 0, 'function', 'parameters', 'properties')
        assert function_properties.key?('schema_key')
        assert_equal 'string', function_properties['schema_key']['type']
        assert function_properties.key?('schema_key_explanation')
        assert_equal 'string', function_properties['schema_key_explanation']['type']

        true
      end
    end

    def test_google_request
      text = "Input Text"
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::DataExtractor.call(text, schema, config: { provider: 'google' })

      assert_requested(:post, /https:\/\/generativelanguage\.googleapis\.com\/v1beta\/models\/.*:generateContent/) do |req|
        request_body = JSON.parse(req.body)

        assert_includes request_body['contents'], { 'role' => 'user', 'parts' => [{ 'text' => text }] }
        assert request_body['contents'].find { |c| c['parts'][0]['text'].include?('schema_key') && c['parts'][0]['text'].include?('schema_key_explanation') }

        true
      end
    end

    def test_anthropic_request
      text = "Input Text"
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::DataExtractor.call(text, schema, config: { provider: 'anthropic' })

      assert_requested(:post, "https://api.anthropic.com/v1/messages") do |req|
        request_body = JSON.parse(req.body)

        assert_equal 'user', request_body['messages'][0]['role']
        assert_equal text, request_body['messages'][0]['content']

        assert request_body.key?('tools')
        assert_equal 1, request_body['tools'].length

        tool = request_body['tools'].first
        assert_equal 'data_extractor', tool['name']

        parameters = tool['input_schema']
        assert parameters.key?('properties')

        properties = parameters['properties']
        assert properties.key?('schema_key')
        assert_equal 'string', properties['schema_key']['type']
        assert properties.key?('schema_key_explanation')
        assert_equal 'string', properties['schema_key_explanation']['type']

        true
      end
    end

    def test_deepseek_request
      text = "Input Text"
      schema = { schema_key: { type: 'string' } }

      ActiveGenie::DataExtractor.call(text, schema, config: { provider: 'deepseek' })

      assert_requested(:post, "https://api.deepseek.com/v1/chat/completions") do |req|
        request_body = JSON.parse(req.body)

        assert_includes request_body['messages'], { 'role' => 'user', 'content' => text }

        function_properties = request_body.dig('tools', 0, 'function', 'parameters', 'properties')
        assert function_properties.key?('schema_key')
        assert_equal 'string', function_properties['schema_key']['type']
        assert function_properties.key?('schema_key_explanation')
        assert_equal 'string', function_properties['schema_key_explanation']['type']

        true
      end
    end
  end
end

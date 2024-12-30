require 'net/http'
require_relative '../../lib/requester/openai.rb'

RSpec.describe ActiveGenerative::Requester::Openai do
  let(:valid_messages) { [{ role: 'user', content: 'Hello' }] }
  let(:valid_function) { { name: 'test', parameters: {} } }
  let(:valid_config) do
    {
      'model' => 'gpt-3.5-turbo',
      'api_key' => 'test-key',
      'organization' => 'test-org'
    }
  end
  let(:valid_response) do
    {
      'choices' => [
        { 'message' => { 'content' => '{"result": "test"}' } }
      ]
    }
  end

  describe '.function_calling' do
    it 'makes successful API call with valid parameters' do
      allow(described_class).to receive(:request).and_return(valid_response)
      
      result = described_class.function_calling(valid_messages, valid_function, valid_config)
      expect(result).to eq({ 'result' => 'test' })
    end

    it 'raises error when model is nil' do
      config = valid_config.merge('model' => nil)
      
      expect {
        described_class.function_calling(valid_messages, valid_function, config)
      }.to raise_error('Model not found')
    end

    it 'returns nil when JSON parsing fails' do
      invalid_response = {
        'choices' => [
          { 'message' => { 'content' => 'invalid-json' } }
        ]
      }
      allow(described_class).to receive(:request).and_return(invalid_response)
      
      result = described_class.function_calling(valid_messages, valid_function, valid_config)
      expect(result).to be_nil
    end
  end

  describe '.request' do
    let(:valid_headers) do
      {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-key',
        'Openai-Organization': 'test-org'
      }
    end
    let(:valid_payload) do
      {
        messages: valid_messages,
        model: 'gpt-3.5-turbo',
      }
    end

    it 'handles successful request' do
      http_response = instance_double(Net::HTTPSuccess, 
        body: valid_response.to_json,
        is_a?: true
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      result = described_class.request(valid_payload, valid_headers)
      expect(Net::HTTP).to have_received(:post).with(
        URI(described_class::API_URL),
        valid_payload.to_json, valid_headers
      )
    end

    it 'raises OpenaiError for unsuccessful response' do
      http_response = instance_double(Net::HTTPBadRequest,
        body: 'error',
        is_a?: false
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      expect {
        described_class.request(valid_payload, valid_headers)
      }.to raise_error(ActiveGenerative::Requester::Openai::OpenaiError)
    end

    it 'returns nil for empty response body' do
      http_response = instance_double(Net::HTTPSuccess,
        body: '',
        is_a?: true
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      result = described_class.request(valid_payload, valid_headers)
      expect(result).to be_nil
    end

    it 'returns nil for invalid JSON response' do
      http_response = instance_double(Net::HTTPSuccess,
        body: 'invalid-json',
        is_a?: true
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      result = described_class.request(valid_payload, valid_headers)
      expect(result).to be_nil
    end

    it 'handles network errors' do
      allow(Net::HTTP).to receive(:post).and_raise(SocketError)

      expect {
        described_class.request(valid_payload, valid_headers)
      }.to raise_error(SocketError)
    end
  end
end

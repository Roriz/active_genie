require_relative '../../lib/requester/openai'

RSpec.describe ActiveGenie::Openai do
  let(:messages) { [{ role: 'user', content: 'Hello' }] }
  let(:function) { { name: 'test', parameters: {} } }
  let(:config) do
    {
      'model' => 'gpt-4o-mini',
      'api_key' => 'secret-key',
      'organization' => 'test-org'
    }
  end
  let(:response) do
    {
      'choices' => [
        { 'message' => { 'content' => '{"result": "test"}' } }
      ]
    }
  end

  describe '.function_calling' do
    it 'makes successful API call with valid parameters' do
      allow(described_class).to receive(:request).and_return(response)
      
      result = described_class.function_calling(messages, function, config)
      expect(result).to eq({ 'result' => 'test' })
    end

    it 'returns nil when JSON parsing fails' do
      response = {
        'choices' => [
          { 'message' => { 'content' => 'invalid-json' } }
        ]
      }
      allow(described_class).to receive(:request).and_return(response)
      
      result = described_class.function_calling(messages, function, config)
      expect(result).to be_nil
    end
  end

  describe '.request' do
    let(:headers) do
      {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret-key',
        'Openai-Organization': 'test-org'
      }
    end
    let(:payload) do
      {
        messages: messages,
        model: 'gpt-4o-mini',
      }
    end

    it 'handles successful request' do
      http_response = instance_double(Net::HTTPSuccess, 
        body: response.to_json,
        is_a?: true
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      result = described_class.request(payload, headers)
      expect(Net::HTTP).to have_received(:post).with(
        URI(described_class::API_URL),
        payload.to_json, headers
      )
    end

    it 'raises OpenaiError for unsuccessful response' do
      http_response = instance_double(Net::HTTPBadRequest,
        body: 'error',
        is_a?: false
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      expect {
        described_class.request(payload, headers)
      }.to raise_error(ActiveGenie::Openai::OpenaiError)
    end

    it 'returns nil for empty response body' do
      http_response = instance_double(Net::HTTPSuccess,
        body: '',
        is_a?: true
      )
      allow(Net::HTTP).to receive(:post).and_return(http_response)

      result = described_class.request(payload, headers)
      expect(result).to be_nil
    end

    it 'handles network errors' do
      allow(Net::HTTP).to receive(:post).and_raise(SocketError)

      expect {
        described_class.request(payload, headers)
      }.to raise_error(SocketError)
    end
  end
end

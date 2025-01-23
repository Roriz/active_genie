RSpec.describe ActiveGenie::DataExtractor do
  let(:message) { "Hi, my name is John Doe and I'm 30 years old" }
  let(:data_to_extract) do
    {
      name: { type: 'string', description: 'The full name of the person' },
      age: { type: 'integer', description: 'The age of the person' }
    }
  end
  let(:http_response) do
    http_response = instance_double(Net::HTTPSuccess, 
      body: {
        choices: [
          {
            message: {
              content: '{"name": "John Doe", "name_explaination": "The full name of the person", "age": 30, "age_explaination": "The age of the person"}'
            }
          }
        ]
      }.to_json,
      is_a?: true
    )
  end

  before do
    allow(Net::HTTP).to receive(:post).and_return(http_response)
  end

  describe '.call' do
    it 'extracts data according to schema' do
      result = described_class.call(message, data_to_extract)

      expect(result['name']).to eq('John Doe')
      expect(result['name_explaination']).to be_a(String)
      expect(result['age']).to eq(30)
      expect(result['age_explaination']).to be_a(String)
    end
  end

  describe '.from_informal' do
    let(:litote_message) { "I'm not unhappy with the service" }
    let(:http_response) do
      http_response = instance_double(Net::HTTPSuccess, 
        body: {
          choices: [
            {
              message: {
                content: '{"name": "John Doe", "name_explaination": "The full name of the person", "age": 30, "age_explaination": "The age of the person", "message_litote": false, "litote_rephrased": ""}'
              }
            }
          ]
        }.to_json,
        is_a?: true
      )
    end

    it 'detects litotes and rephrases them' do
      result = described_class.from_informal(litote_message, data_to_extract)

      expect(result['message_litote']).to be false
    end

    it 'still extracts regular data' do
      result = described_class.from_informal(message, data_to_extract)

      expect(result['name']).to eq('John Doe')
      expect(result['age']).to eq(30)
    end
  end
end

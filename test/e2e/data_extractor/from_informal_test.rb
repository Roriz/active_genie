# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::DataExtractor::FromInformalTest < Minitest::Test
  TESTS = [
    # Litotes test cases
    { input: ["The weather isn't bad today", { mood: { type: 'boolean' } }], expected: { mood: true } },
    { input: ["This restaurant isn't terrible", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["The service was not bad at all", { rating: { type: 'boolean' } }], expected: { rating: true } },
    { input: ["The movie wasn't horrible", { review: { type: 'boolean' } }], expected: { review: true } },
    
    # Affirmative expressions
    { input: ["No problem, I can help with that", { willingness: { type: 'boolean' } }], expected: { willingness: true } },
    { input: ["Sure, no worries at all", { agreement: { type: 'boolean' } }], expected: { agreement: true } },
    { input: ["No doubt about it", { certainty: { type: 'boolean' } }], expected: { certainty: true } },
    
    # Negative expressions
    { input: ["Nah, I don't think so", { response: { type: 'boolean' } }], expected: { response: false } },
    { input: ["Not really interested in that", { interest: { type: 'boolean' } }], expected: { interest: false } },
    { input: ["I'm not sure about this", { confidence: { type: 'boolean' } }], expected: { confidence: false } },
    { input: ["That's not what I meant", { person_has_agreed: { type: 'boolean' } }], expected: { person_has_agreed: false } },
  ]

  TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::DataExtractor::FromInformal.call(*test[:input])

      test[:expected].each do |key, value|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        assert_equal result[key.to_s], value
      end
    end
  end
end
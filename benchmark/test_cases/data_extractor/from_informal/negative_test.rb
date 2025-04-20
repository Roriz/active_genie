# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::DataExtractor::NegativeTest < Minitest::Test
  TESTS = [
    { input: ["Nah, I don't think so", { response: { type: 'boolean' } }], expected: { response: false } },
    { input: ["Not really interested in that", { interest: { type: 'boolean' } }], expected: { interest: false } },
    { input: ["I'm not sure about this", { confidence: { type: 'boolean' } }], expected: { confidence: false } },
    { input: ["That's not what I meant", { person_has_agreed: { type: 'boolean' } }], expected: { person_has_agreed: false } },
    { input: ["Well, at least you tried", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["That's certainly one way to do it", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You did your best, I suppose", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["Not bad, considering your experience", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["It's impressive how consistent you are at this level", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You always surprise me, just not in the way I hope", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You have a unique approach, that's for sure", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["I wouldn't have thought of doing it that way", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["It's good to see you haven't changed", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You really put effort into that, didn't you?", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You always keep things interesting", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["That was a bold choice", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You definitely made an impression", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You always stand out in a crowd", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You certainly have a style", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["That was unforgettable", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You never fail to deliver something unexpected", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["It's nice to see someone so committed", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You always bring something new to the table", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
    { input: ["You have a talent for surprising people", { backhanded: { type: 'boolean' }, negative_sentiment: { type: 'boolean' } }], expected: { backhanded: true, negative_sentiment: true } },
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
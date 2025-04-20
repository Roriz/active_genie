# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::DataExtractor::AffirmativeTest < Minitest::Test
  TESTS = [
    { input: ["No problem, I can help with that", { willingness: { type: 'boolean' } }], expected: { willingness: true } },
    { input: ["Sure, no worries at all", { agreement: { type: 'boolean' } }], expected: { agreement: true } },
    { input: ["No doubt about it", { certainty: { type: 'boolean' } }], expected: { certainty: true } },
    { input: ["Not bad at all!", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["I can't complain", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["It's not the worst I've seen", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["You won't regret it", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["I have no doubt you'll succeed", { certainty: { type: 'boolean' } }], expected: { certainty: true } },
    { input: ["There's nothing I would change", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["I wouldn't miss it for the world", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["You don't disappoint", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["It's not just good—it's  amazing!", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["I don't hate it—in fact, I love it", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["You never fail to impress", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["I can't thank you enough", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["Not only is it good, it's fantastic", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["I wouldn't say no to that", { willingness: { type: 'boolean' } }], expected: { willingness: true } },
    { input: ["I can't imagine a better outcome", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["It's not every day you see something this great", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["I don't think I've ever been happier", { happiness: { type: 'boolean' } }], expected: { happiness: true } },
    { input: ["I wouldn't trade this for anything", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["You don't see talent like this every day", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
    { input: ["I never expected it to turn out this well", { satisfaction: { type: 'boolean' } }], expected: { satisfaction: true } },
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
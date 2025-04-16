# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::DataExtractor::FromInformalTest < Minitest::Test
  TESTS = [
    # Litotes test cases
    { input: ["The weather isn't bad today", { mood: { type: 'boolean' } }], expected: { mood: true } },
    { input: ["This restaurant isn't terrible", { quality: { type: 'boolean' } }], expected: { quality: true } },
    { input: ["The service was not bad at all", { rating: { type: 'boolean' } }], expected: { rating: true } },
    { input: ["The movie wasn't horrible", { review: { type: 'boolean' } }], expected: { review: true } },
    { input: ["He's not unfamiliar with hard work", { diligent: { type: 'boolean' } }], expected: { diligent: true } },
    { input: ["That wasn't the worst meal I've ever had", { meal_quality: { type: 'boolean' } }], expected: { meal_quality: true } },
    { input: ["She's not exactly a beginner at chess", { experience: { type: 'boolean' } }], expected: { experience: true } },
    { input: ["The weather isn't too bad today", { weather: { type: 'boolean' } }], expected: { weather: true } },
    { input: ["He's no fool", { intelligence: { type: 'boolean' } }], expected: { intelligence: true } },
    { input: ["It's not uncommon to see rain in April", { frequency: { type: 'boolean' } }], expected: { frequency: true } },
    { input: ["She's not unkind", { kindness: { type: 'boolean' } }], expected: { kindness: true } },
    { input: ["That's not a small accomplishment", { accomplishment: { type: 'boolean' } }], expected: { accomplishment: true } },
    { input: ["He's not without talent", { talent: { type: 'boolean' } }], expected: { talent: true } },
    { input: ["The movie wasn't uninteresting", { interest: { type: 'boolean' } }], expected: { interest: true } },
    { input: ["She's not the quietest person in the room", { talkative: { type: 'boolean' } }], expected: { talkative: true } },
    { input: ["That's not a bad idea", { idea: { type: 'boolean' } }], expected: { idea: true } },
    { input: ["He's not the least bit concerned", { concern: { type: 'boolean' } }], expected: { concern: false } },
    { input: ["The test wasn't impossible", { test_difficulty: { type: 'boolean' } }], expected: { test_difficulty: true } },
    { input: ["She's not unhappy with the results", { happiness: { type: 'boolean' } }], expected: { happiness: true } },
    { input: ["The solution isn't without merit", { merit: { type: 'boolean' } }], expected: { merit: true } },
    { input: ["He's not the slowest runner on the team", { speed: { type: 'boolean' } }], expected: { speed: true } },
    { input: ["That's not an insignificant sum of money", { sum_significance: { type: 'boolean' } }], expected: { sum_significance: true } },
    { input: ["She's not completely wrong", { correctness: { type: 'boolean' } }], expected: { correctness: true } },
    { input: ["The book isn't lacking in humor", { humor: { type: 'boolean' } }], expected: { humor: true } },
    
    # Affirmative expressions
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

    # Negative expressions
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
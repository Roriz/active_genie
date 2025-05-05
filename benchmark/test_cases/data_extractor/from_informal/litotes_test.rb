# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveGenie
  module DataExtractor
    class LitotesTest < Minitest::Test
      TESTS = [
        { input: ["The weather isn't bad today", { mood: { type: 'boolean' } }], expected: { mood: true } },
        { input: ["This restaurant isn't terrible", { quality: { type: 'boolean' } }], expected: { quality: true } },
        { input: ['The service was not bad at all', { rating: { type: 'boolean' } }], expected: { rating: true } },
        { input: ["The movie wasn't horrible", { review: { type: 'boolean' } }], expected: { review: true } },
        { input: ["He's not unfamiliar with hard work", { diligent: { type: 'boolean' } }],
          expected: { diligent: true } },
        { input: ["That wasn't the worst meal I've ever had", { meal_quality: { type: 'boolean' } }],
          expected: { meal_quality: true } },
        { input: ["She's not exactly a beginner at chess", { experience: { type: 'boolean' } }],
          expected: { experience: true } },
        { input: ["The weather isn't too bad today", { weather: { type: 'boolean' } }], expected: { weather: true } },
        { input: ["He's no fool", { intelligence: { type: 'boolean' } }], expected: { intelligence: true } },
        { input: ["It's not uncommon to see rain in April", { frequency: { type: 'boolean' } }],
          expected: { frequency: true } },
        { input: ["She's not unkind", { kindness: { type: 'boolean' } }], expected: { kindness: true } },
        { input: ["That's not a small accomplishment", { accomplishment: { type: 'boolean' } }],
          expected: { accomplishment: true } },
        { input: ["He's not without talent", { talent: { type: 'boolean' } }], expected: { talent: true } },
        { input: ["The movie wasn't uninteresting", { interest: { type: 'boolean' } }], expected: { interest: true } },
        { input: ["She's not the quietest person in the room", { talkative: { type: 'boolean' } }],
          expected: { talkative: true } },
        { input: ["That's not a bad idea", { idea: { type: 'boolean' } }], expected: { idea: true } },
        { input: ["He's not the least bit concerned", { concern: { type: 'boolean' } }], expected: { concern: false } },
        { input: ["The test wasn't impossible", { test_difficulty: { type: 'boolean' } }],
          expected: { test_difficulty: true } },
        { input: ["She's not unhappy with the results", { happiness: { type: 'boolean' } }],
          expected: { happiness: true } },
        { input: ["The solution isn't without merit", { merit: { type: 'boolean' } }], expected: { merit: true } },
        { input: ["He's not the slowest runner on the team", { speed: { type: 'boolean' } }],
          expected: { speed: true } },
        { input: ["That's not an insignificant sum of money", { sum_significance: { type: 'boolean' } }],
          expected: { sum_significance: true } },
        { input: ["She's not completely wrong", { correctness: { type: 'boolean' } }],
          expected: { correctness: true } },
        { input: ["The book isn't lacking in humor", { humor: { type: 'boolean' } }], expected: { humor: true } }
      ].freeze

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
  end
end

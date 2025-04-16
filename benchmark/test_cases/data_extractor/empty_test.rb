# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::DataExtractor::EmptyTest < Minitest::Test
  EMPTY = [
    { input: ["@alice posted: Just finished reading 'Atomic Habits'! Highly recommend it.", { price: { type: 'number' } }], expected: { price: 0 } },
    { input: ["bob commented: Congrats on your new job, @alice!",                           { price: { type: 'number' } }], expected: { price: 0 } },
    { input: ["@carol liked @dave's photo.",                                                { price: { type: 'number' } }], expected: { price: 0 } },
    { input: ["Friends: The Complete Series Collection (25th Anniversary/Repackaged/DVD) - \$59.99", { price: { type: 'number' }, ship_price: { type: 'number' } }], expected: { price: 59.99, ship_price: 0 } },
    { input: ["The Beatles: Get Back [3 Blu-ray] - Director: Peter Jackson - \$27.99", { price: { type: 'number' }, ship_price: { type: 'number' } }], expected: { price: 27.99, ship_price: 0 } },
    { input: ["Red Dead Redemption 2 - PlayStation 4 - ESRB Rating: Mature 17+ - \$39.99", { price: { type: 'number' }, ship_price: { type: 'number' } }], expected: { price: 39.99, ship_price: 0 } },
  ]

  EMPTY.each_with_index do |test, index|
    define_method("test_data_extractor_empty_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}") do
      result = ActiveGenie::DataExtractor::Basic.call(*test[:input])

      test[:expected].each do |key, value|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        assert_equal value, result[key.to_s], "Expected (#{key}) #{value}, but was #{result[key.to_s]}"
      end
    end
  end
end
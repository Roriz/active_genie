# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveGenie
  module DataExtractor
    class EmptyTest < Minitest::Test
      EMPTY = [
        {
          input: ["@alice posted: Just finished reading 'Atomic Habits'! Highly recommend it.",
                  { price: { type: 'number' } }], expected: {}
        },
        {
          input: ['bob commented: Congrats on your new job, @alice!',
                  { price: { type: 'number' } }], expected: {}
        },
        {
          input: ["@carol liked @dave's photo.",
                  { price: { type: 'number' } }], expected: {}
        },
        {
          input: ['Friends: The Complete Series Collection (25th Anniversary/Repackaged/DVD) - $59.99',
                  { price: { type: 'number' },
                    ship_price: { type: 'number' } }], expected: { price: 59.99 }
        },
        {
          input: ['The Beatles: Get Back [3 Blu-ray] - Director: Peter Jackson - $27.99',
                  { price: { type: 'number' },
                    ship_price: { type: 'number' } }], expected: { price: 27.99 }
        },
        {
          input: ['Red Dead Redemption 2 - PlayStation 4 - ESRB Rating: Mature 17+ - $39.99',
                  { price: { type: 'number' },
                    ship_price: { type: 'number' } }], expected: { price: 39.99 }
        }
      ].freeze

      EMPTY.each_with_index do |test, _index|
        define_method("test_data_extractor_empty_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}") do
          result = ActiveGenie::DataExtractor.call(*test[:input])

          test[:expected].each do |key, value|
            assert result.key?(key), "Missing key: #{key}, result: #{result[0..100]}"
            assert_equal value, result[key], "Expected (#{key}) #{value}, but was #{result[key]}"
          end

          return unless test[:expected].keys.empty?

          assert_equal result.keys.size, 0, "Expected no keys, but was #{result.keys.size}"
        end
      end
    end
  end
end

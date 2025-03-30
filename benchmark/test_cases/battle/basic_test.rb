# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::Battle::BasicTest < Minitest::Test
  TESTS = [
    { input: ['american food', 'brazilian food', 'less fat is better'], expected: 'player_2' },
    { input: ['rainning day', 'sunny day', 'go to park with family'], expected: 'player_2' },
    { input: ['python', 'javascript', 'data science and machine learning tasks'], expected: 'player_1' },
    { input: ['bicycle', 'car', 'environmentally friendly urban commuting'], expected: 'player_1' },
    { input: ['reading a book', 'watching tv', 'cognitive development and relaxation'], expected: 'player_1' },
    { input: ['yoga', 'weightlifting', 'stress relief and flexibility improvement'], expected: 'player_1' },
    { input: ['online course', 'in-person class', 'flexible schedule and cost effectiveness'], expected: 'player_1' },
    { input: ['video call', 'text message', 'discussing complex emotional topics'], expected: 'player_1' },
    { input: ['remote work', 'office work', 'work-life balance and productivity'], expected: 'player_1' },
    { input: ['Kiki', 'Bouba', 'what sounds is more aggressive?'], expected: 'player_1' }
  ]

  TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][2].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::Battle.basic(*test[:input])

      assert_equal test[:expected], result['winner']
    end
  end
end
# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::Battle::BasicTest < Minitest::Test
  TESTS = [
    { input: ['flutter', 'react native', 'stability and performance'], expected: 'flutter' },
    { input: ['american food', 'brazilian food', 'less fat is better'], expected: 'brazilian food' },
    { input: ['rainning day', 'sunny day', 'go to park with family'], expected: 'sunny day' },
    { input: ['python', 'javascript', 'data science and machine learning tasks'], expected: 'python' },
    { input: ['bicycle', 'car', 'environmentally friendly urban commuting'], expected: 'bicycle' },
    { input: ['reading a book', 'watching tv', 'cognitive development and relaxation'], expected: 'reading a book' },
    { input: ['yoga', 'weightlifting', 'stress relief and flexibility improvement'], expected: 'yoga' },
    { input: ['online course', 'in-person class', 'flexible schedule and cost effectiveness'], expected: 'online course' },
    { input: ['video call', 'text message', 'discussing complex emotional topics'], expected: 'video call' },
    { input: ['remote work', 'office work', 'work-life balance and productivity'], expected: 'remote work' }
  ]

  TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][2].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::Battle.basic(*test[:input])

      assert_equal test[:expected], result['winner']
    end
  end
end
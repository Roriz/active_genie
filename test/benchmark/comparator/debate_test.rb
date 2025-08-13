# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Comparator
    class DebateTest < Minitest::Test
      TESTS = [
        { input: ['american food', 'brazilian food', 'less fat is better'], expected: 1 },
        { input: ['rainning day', 'sunny day', 'go to park with family'], expected: 0 },
        { input: ['python', 'javascript', 'data science and machine learning tasks'], expected: 0 },
        { input: ['bicycle', 'car', 'environmentally friendly urban commuting'], expected: 0 },
        { input: ['reading a book', 'watching tv', 'cognitive development and relaxation'], expected: 0 },
        { input: ['yoga', 'weightlifting', 'stress relief and flexibility improvement'], expected: 0 },
        { input: ['online course', 'in-person class', 'flexible schedule and cost effectiveness'], expected: 0 },
        { input: ['video call', 'text message', 'discussing complex emotional topics'], expected: 0 },
        { input: ['remote work', 'office work', 'work-life balance and productivity'], expected: 0 },
        { input: ['Kiki', 'Bouba', 'what sounds is more aggressive?'], expected: 0 }
      ].freeze

      TESTS.each_with_index do |test, index|
        define_method("test_#{test[:input][2].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
          result = ActiveGenie::Comparator.debate(*test[:input])

          assert_equal test[:input][test[:expected]], result.winner
        end
      end

      def test_dress_for_friday_night
        dresses = [
          'Experience ultimate comfort with our Cozy Cielo Home Dress. Made from a soft cotton blend, it features a relaxed fit, scoop neckline, and convenient side pockets. Available in calming colors, this knee-length dress ensures you look chic while feeling at ease. Easy to care for and machine washable, it\'s a versatile wardrobe staple you\'ll love.',
          'Turn heads with our Glamour Noir Dress. Crafted from a luxurious, shimmering fabric, this dress features a sleek, form-fitting silhouette and an elegant V-neckline. The midi length and sophisticated design promise a stunning look, while the subtle side slit adds a touch of allure. Available in timeless black, the Glamour Noir Dress is perfect for dinners or nights out. Effortlessly chic and machine washable, it\'s the go-to choice for your next night on the town.'
        ]
        criteria = 'Dress for Friday night'
        result = ActiveGenie::Comparator.debate(
          dresses[0],
          dresses[1],
          criteria
        )

        assert_equal dresses[1], result.winner
      end

      def test_stackoverflow_questions
        stackoverflow_issues = [
          'I\'ve ruled out race conditions, but JIT optimizations might be reordering instructions unpredictably. Profiling suggests a cache coherency issue, possibly tied to memory fences or weak memory ordering on ARM. Has anyone encountered a similar JIT-induced anomaly that only manifests under specific CPU architectures?',
          'How do I print "Hello, World!" in Python?'
        ]
        criteria = 'What is the most hardest question'
        result = ActiveGenie::Comparator.debate(
          stackoverflow_issues[0],
          stackoverflow_issues[1],
          criteria
        )

        assert_equal stackoverflow_issues[0], result.winner
      end
    end
  end
end

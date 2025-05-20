# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Battle
    class GeneralistTest < Minitest::Test
      TESTS = [
        { input: ['american food', 'brazilian food', 'less fat is better'], expected: 'player_b' },
        { input: ['rainning day', 'sunny day', 'go to park with family'], expected: 'player_b' },
        { input: ['python', 'javascript', 'data science and machine learning tasks'], expected: 'player_a' },
        { input: ['bicycle', 'car', 'environmentally friendly urban commuting'], expected: 'player_a' },
        { input: ['reading a book', 'watching tv', 'cognitive development and relaxation'], expected: 'player_a' },
        { input: ['yoga', 'weightlifting', 'stress relief and flexibility improvement'], expected: 'player_a' },
        { input: ['online course', 'in-person class', 'flexible schedule and cost effectiveness'],
          expected: 'player_a' },
        { input: ['video call', 'text message', 'discussing complex emotional topics'], expected: 'player_a' },
        { input: ['remote work', 'office work', 'work-life balance and productivity'], expected: 'player_a' },
        { input: ['Kiki', 'Bouba', 'what sounds is more aggressive?'], expected: 'player_a' }
      ].freeze

      TESTS.each_with_index do |test, index|
        define_method("test_#{test[:input][2].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
          result = ActiveGenie::Battle.call(*test[:input])

          assert_equal test[:expected], result['winner']
        end
      end

      def test_dress_for_friday_night
        dresses = [
          'Experience ultimate comfort with our Cozy Cielo Home Dress, perfect for relaxing or casual outings. Made from a soft cotton blend, it features a relaxed fit, scoop neckline, and convenient side pockets. Available in calming colors, this knee-length dress ensures you look chic while feeling at ease. Easy to care for and machine washable, it\'s a versatile wardrobe staple you\'ll love.',
          'Turn heads with our Glamour Noir Dress, ideal for your evening plans. Crafted from a luxurious, shimmering fabric, this dress features a sleek, form-fitting silhouette and an elegant V-neckline. The midi length and sophisticated design promise a stunning look, while the subtle side slit adds a touch of allure. Available in timeless black, the Glamour Noir Dress is perfect for dinners or nights out. Effortlessly chic and machine washable, it\'s the go-to choice for your next night on the town.'
        ]
        criteria = 'Dress for Friday night'
        result = ActiveGenie::Battle.call(
          dresses[0],
          dresses[1],
          criteria
        )

        assert_equal 'player_b', result['winner']
      end

      def test_stackoverflow_questions
        stackoverflow_issues = [
          'I\'ve ruled out race conditions, but JIT optimizations might be reordering instructions unpredictably. Profiling suggests a cache coherency issue, possibly tied to memory fences or weak memory ordering on ARM. Has anyone encountered a similar JIT-induced anomaly that only manifests under specific CPU architectures?',
          'How do I print "Hello, World!" in Python?'
        ]
        criteria = 'What is the most hardest question'
        result = ActiveGenie::Battle.call(
          stackoverflow_issues[0],
          stackoverflow_issues[1],
          criteria
        )

        assert_equal 'player_a', result['winner']
      end
    end
  end
end

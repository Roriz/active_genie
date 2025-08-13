# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Scorer
    class GoodscoresTest < Minitest::Test
      def test_evaluate_bug_report
        result = ActiveGenie::Scorer.jury_bench('idk the app keeps crashing sometimes when i try to do stuff. maybe fix it?',
                                           'Evaluate bug report quality and actionability', ['qa_engineer'])

        assert_operator result['final_score'], :>=, 50, "Expected to be at greater than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 80, "Expected to be at less than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_legal_accuracy
        result = ActiveGenie::Scorer.jury_bench(
          'Our new product uses AI and blockchain technology with quantum computing capabilities to revolutionize the industry with cutting-edge solutions that leverage synergistic paradigms.', 'Evaluate legal accuracy and technical precision', ['legal_expert']
        )

        assert_operator result['final_score'], :>=, 50, "Expected to be at greater than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 80, "Expected to be at less than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_code_review_feedback
        result = ActiveGenie::Scorer.jury_bench(
          'The code has bugs. I tried to fix them but they are still there. The performance is also not good, we should optimize it.', 'Evaluate code review feedback quality', ['senior_software_engineer']
        )

        assert_operator result['final_score'], :>=, 50, "Expected to be at greater than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 80, "Expected to be at less than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_technical_accuracy
        result = ActiveGenie::Scorer.jury_bench(
          'Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity.', 'Evaluate technical accuracy and depth of explanation', ['machine_learning_engineer']
        )

        assert_operator result['final_score'], :>=, 50, "Expected to be at greater than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 80, "Expected to be at less than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end
    end
  end
end

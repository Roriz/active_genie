# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::Scoring::GreateScoresTest < Minitest::Test
  GREAT_SCORE_TESTS = [
    { input: ['Introducing our new AI-powered smart home system that learns your preferences and automatically adjusts lighting, temperature, and security settings. Save energy and enjoy personalized comfort with minimal effort.', 'Evaluate marketing effectiveness and accuracy of technical claims', ['marketing_specialist']], expected: 90 },
    { input: ['To reset your password: 1. Click "Forgot Password" 2. Enter your email 3. Check your inbox for reset link 4. Click the link 5. Enter new password 6. Confirm new password', 'Evaluate clarity and completeness of instructions', ['ux_writer']], expected: 90 },
    { input: ['PR implements rate limiting using in memory cache with a sliding window algorithm. Added unit tests covering edge cases and included performance benchmarks showing 99th percentile latency under 50ms.', 'Evaluate code review quality and completeness', ['senior_software_engineer']], expected: 90 },
    { input: ['Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity. Practical usage example could be Sensors collect real-time machine data (temperature, vibration) and an ML model (e.g., Random Forest or LSTM) predicts failures based on extracted features. This enables proactive maintenance, reducing downtime and costs.', 'Evaluate educational value and technical accuracy', ['ml_expert']], expected: 90 },
  ]
  
  def test_evaluate_marketing_effectiveness
    result = ActiveGenie::Scoring::Basic.call('Introducing our new AI-powered smart home system that learns your preferences and automatically adjusts lighting, temperature, and security settings. Save energy and enjoy personalized comfort with minimal effort.', 'Evaluate marketing effectiveness and accuracy of technical claims', ['marketing_specialist'])

    assert_equal result['final_score'] >= 80, true, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_clarity
    result = ActiveGenie::Scoring::Basic.call('To reset your password: 1. Click "Forgot Password" 2. Enter your email 3. Check your inbox for reset link 4. Click the link 5. Enter new password 6. Confirm new password', 'Evaluate clarity and completeness of instructions', ['ux_writer'])

    assert_equal result['final_score'] >= 80, true, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_code_review_quality
    result = ActiveGenie::Scoring::Basic.call('PR implements rate limiting using in memory cache with a sliding window algorithm. Added unit tests covering edge cases and included performance benchmarks showing 99th percentile latency under 50ms.', 'Evaluate code review quality and completeness', ['senior_software_engineer'])

    assert_equal result['final_score'] >= 80, true, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_educational_value
    result = ActiveGenie::Scoring::Basic.call('Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity. Practical usage example could be Sensors collect real-time machine data (temperature, vibration) and an ML model (e.g., Random Forest or LSTM) predicts failures based on extracted features. This enables proactive maintenance, reducing downtime and costs.', 'Evaluate educational value and technical accuracy', ['ml_expert'])

    assert_equal result['final_score'] >= 80, true, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end
end
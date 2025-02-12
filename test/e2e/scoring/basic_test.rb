# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::Scoring::BasicTest < Minitest::Test
  GREAT_SCORE_TESTS = [
    { input: ['Introducing our new AI-powered smart home system that learns your preferences and automatically adjusts lighting, temperature, and security settings. Save energy and enjoy personalized comfort with minimal effort.', 'Evaluate marketing effectiveness and accuracy of technical claims', ['marketing_specialist']], expected: 90 },
    { input: ['To reset your password: 1. Click "Forgot Password" 2. Enter your email 3. Check your inbox for reset link 4. Click the link 5. Enter new password 6. Confirm new password', 'Evaluate clarity and completeness of instructions', ['ux_writer']], expected: 90 },
    { input: ['PR implements rate limiting using in memory cache with a sliding window algorithm. Added unit tests covering edge cases and included performance benchmarks showing 99th percentile latency under 50ms.', 'Evaluate code review quality and completeness', ['senior_software_engineer']], expected: 90 },
    { input: ['Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity. Practical usage example could be Sensors collect real-time machine data (temperature, vibration) and an ML model (e.g., Random Forest or LSTM) predicts failures based on extracted features. This enables proactive maintenance, reducing downtime and costs.', 'Evaluate educational value and technical accuracy', ['ml_expert']], expected: 90 },
  ]

  GOOD_SCORE_TESTS = [
    { input: ['System crashes when processing files larger than 2GB on the home page. Steps to reproduce: 1. Select file >2GB 2. Click upload 3. System freezes and returns Error 500. Occurs on Chrome 120 and Firefox 115. Effected user_id: 980. Is possible reproduce on the demo account in staging, happens 100% of the time', 'Evaluate bug report quality and technical detail', ['qa_engineer']], expected: 70 },
    { input: ['This privacy policy outlines how we collect, process, and store user data in compliance with GDPR and CCPA requirements. We employ industry-standard encryption for all data transmissions.', 'Evaluate legal accuracy and technical precision', ['legal_expert']], expected: 70 },
    { input: ['The authentication service must support SSO via OAuth 2.0 and SAML 2.0, handle up to 10,000 requests per second, and maintain 99.99% uptime. All sensitive data must be encrypted at rest using AES-256.', 'Evaluate technical completeness and clarity of requirements', ['system_architect']], expected: 70 },
    { input: ['Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity.', 'Evaluate technical accuracy and depth of explanation', ['machine_learning_engineer']], expected: 70 },
  ]

  BAD_SCORE_TESTS = [
    { input: ['idk the app keeps crashing sometimes when i try to do stuff. maybe fix it?', 'Evaluate bug report quality and actionability', ['qa_engineer']], expected: 30 },
    { input: ['Our new product uses AI and blockchain technology with quantum computing capabilities to revolutionize the industry with cutting-edge solutions that leverage synergistic paradigms.', 'Evaluate technical accuracy and marketing claims', ['technical_writer']], expected: 30 },
    { input: ['The code has bugs. I tried to fix them but they are still there. The performance is also not good, we should optimize it.', 'Evaluate code review feedback quality', ['senior_software_engineer']], expected: 30 },
  ]

  TERRIBLE_SCORE_TESTS = [
    { input: ['WARNING!!! URGENT!!! System totally broken!!! Nothing works!!! Fix ASAP!!!', 'Evaluate incident report quality and professionalism', ['system_reliability_engineer']], expected: 10 },
    { input: ['Section 3.4: Data must secure. Implement good security. Make system fast.', 'Evaluate completeness and clarity of technical requirements', ['system_architect']], expected: 10 },
  ]

  # (GREAT_SCORE_TESTS + GOOD_SCORE_TESTS + BAD_SCORE_TESTS + TERRIBLE_SCORE_TESTS).each_with_index do |test, index|
  #   define_method("test_#{test[:input][1].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
  #     result = ActiveGenie::Scoring::Basic.call(*test[:input])

  #     assert_equal result['final_score'] >= test[:expected] - 20, true, "Expected to be at greater than #{test[:expected] - 20}, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  #     assert_equal result['final_score'] <= test[:expected] + 20, true, "Expected to be at less than #{test[:expected] + 20}, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  #   end
  # end

  GREAT_SCORE_TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][1].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::Scoring::Basic.call(test[:input][0], test[:input][1])

      assert_equal result['final_score'] >= test[:expected] - 20, true, "Expected to be at greater than #{test[:expected] - 20}, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      assert_equal result['final_score'] <= test[:expected] + 20, true, "Expected to be at less than #{test[:expected] + 20}, but was #{result['final_score']}, because: #{result['final_reasoning']}"
    end
  end
end
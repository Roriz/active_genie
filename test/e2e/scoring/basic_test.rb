# frozen_string_literal: true

require_relative "../../test_helper"

SIMPLE_TESTS = [
  { input: ['Introducing our new AI-powered smart home system that learns your preferences and automatically adjusts lighting, temperature, and security settings. Save energy and enjoy personalized comfort with minimal effort.', 'Evaluate marketing effectiveness and accuracy of technical claims', ['marketing_specialist', 'tech_reviewer']], expected: { final_score: 80 } },
  
  { input: ['To reset your password: 1. Click "Forgot Password" 2. Enter your email 3. Check your inbox for reset link 4. Click the link 5. Enter new password 6. Confirm new password', 'Evaluate clarity and completeness of instructions', ['ux_writer', 'security_expert']], expected: { final_score: 80 } },
  
  { input: ['System crashes when processing files larger than 2GB on the home page. Steps to reproduce: 1. Select file >2GB 2. Click upload 3. System freezes and returns Error 500. Occurs on Chrome 120 and Firefox 115. Effected user_id: 980. Is possible reproduce on the demo account in staging, happens 100% of the time', 'Evaluate bug report quality and technical detail', ['qa_engineer', 'developer']], expected: { final_score: 80 } },
  
  { input: ['This privacy policy outlines how we collect, process, and store user data in compliance with GDPR and CCPA requirements. We employ industry-standard encryption for all data transmissions.', 'Evaluate legal accuracy and technical precision', ['legal_expert', 'privacy_engineer']], expected: { final_score: 80 } },
  
  { input: ['PR implements rate limiting using in memory cache with a sliding window algorithm. Added unit tests covering edge cases and included performance benchmarks showing 99th percentile latency under 50ms.', 'Evaluate code review quality and completeness', ['senior_developer', 'performance_engineer']], expected: { final_score: 80 } },
  
  { input: ['The authentication service must support SSO via OAuth 2.0 and SAML 2.0, handle up to 10,000 requests per second, and maintain 99.99% uptime. All sensitive data must be encrypted at rest using AES-256.', 'Evaluate technical completeness and clarity of requirements', ['system_architect', 'security_analyst']], expected: { final_score: 80 } },
  
  { input: ['Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity.', 'Evaluate educational value and technical accuracy', ['ml_expert', 'educational_content_writer']], expected: { final_score: 80 } }
]

class ActiveGenie::Scoring::BasicTest < Minitest::Test
  SIMPLE_TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][1].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::Scoring::Basic.call(*test[:input])

      test[:expected].each do |key, expected|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        assert_equal result[key.to_s] >= expected, true, "Expected #{key} to be at least #{expected}, but was #{result[key.to_s]}, because: #{result['final_reasoning']}"
      end
    end
  end
end
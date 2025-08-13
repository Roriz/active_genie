# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Scoring
    class GreateScoresTest < Minitest::Test
      def test_evaluate_marketing_effectiveness
        result = ActiveGenie::Scoring.call(
          'Introducing our new AI-powered smart home system that learns your preferences and automatically adjusts lighting, temperature, and security settings. Save energy and enjoy personalized comfort with minimal effort.', 'Evaluate marketing effectiveness and accuracy of technical claims', ['marketing_specialist']
        )

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_clarity
        result = ActiveGenie::Scoring.call(
          'To reset your password: 1. Click "Forgot Password" 2. Enter your email 3. Check your inbox for reset link 4. Click the link 5. Enter new password 6. Confirm new password', 'Evaluate clarity and completeness of instructions', ['ux_writer']
        )

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_code_review_quality
        result = ActiveGenie::Scoring.call(
          'PR implements rate limiting using in memory cache with a sliding window algorithm. Added unit tests covering edge cases and included performance benchmarks showing 99th percentile latency under 50ms.', 'Evaluate code review quality and completeness', ['senior_software_engineer']
        )

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_evaluate_educational_value
        result = ActiveGenie::Scoring.call(
          'Machine learning models can suffer from overfitting when they learn patterns specific to the training data that don\'t generalize well to new data. Common solutions include cross-validation, regularization, and increasing training data diversity. Practical usage example could be Sensors collect real-time machine data (temperature, vibration) and an ML model (e.g., Random Forest or LSTM) predicts failures based on extracted features. This enables proactive maintenance, reducing downtime and costs.', 'Evaluate educational value and technical accuracy', ['ml_expert']
        )

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_marketplace_product_quality
        product_description = <<~PRODUCT_DESCRIPTION
          Sony WH-1000XM5 Wireless Noise-Canceling Headphones - Black - Excellent Condition
          Experience industry-leading noise cancellation with the Sony WH-1000XM5, designed for crystal-clear audio and immersive sound.
          These headphones feature adaptive noise-canceling technology, 30-hour battery life, and ultra-soft ear cushions
          for all-day comfort. This pair is in excellent condition, with minimal signs of wear and fully functional buttons,
          Bluetooth connectivity, and touch controls. Includes the original carrying case, charging cable, and 3.5mm audio cable
          for wired listening. Ships securely via USPS Priority Mail with tracking, and returns are accepted within 30 days
          if the item is not as described. A perfect choice for travelers, commuters, or audiophiles seeking premium sound quality,
          feel free to ask any questions before purchasing!
        PRODUCT_DESCRIPTION
        criteria = <<~CRITERIA
          item description should provide clear details about what is being sold, including the brand, model, size, color, and key features so buyers know exactly what they’re getting. It should honestly state the condition, mentioning if it’s new, like new, or used, and highlight any defects or wear to build trust. The description should confirm the functionality, whether it works perfectly or has minor issues. If any accessories, manuals, or packaging are included, that should be mentioned. Shipping details should specify the method, cost, and estimated delivery time, and the return policy should be clear. The language should be concise, professional, and engaging, making it easy for buyers to read and understand.
        CRITERIA
        result = ActiveGenie::Scoring.call(product_description, criteria,
                                           %w[ebay_seller_moderator ebay_product_analyzer])

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end

      def test_technical_difficulty_of_jira_task
        jira_task = <<~JIRA_TASK
          Develop an AI-powered dynamic pricing engine that automatically
          adjusts product prices in real-time based on market trends,
          competitor pricing, stock levels, and user demand,
          within a high-traffic Rails e-commerce application
        JIRA_TASK
        criteria = <<~CRITERIA
          Analyze technical difficulty of implementing the feature.
          The feature will be built from scratch. Use high scores for the most complex tasks and low scores for the simple tasks
        CRITERIA
        reviewers = %w[
          senior_software_engineer architect_engineer
          devops_engineer software_engineer
        ]

        result = ActiveGenie::Scoring.call(jira_task, criteria, reviewers)

        assert_operator result['final_score'], :>=, 80, "Expected to be at greater than 80, but was #{result['final_score']}, because: #{result['final_reasoning']}"
      end
    end
  end
end

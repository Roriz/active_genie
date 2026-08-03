# frozen_string_literal: true

require_relative '../test_helper'

class SaasFeedbackLitoteTest < Minitest::Test
  def setup
    @feedback_text = load_fixture('saas/churn_feedback.txt')
    @schema = {
      sentiment: {
        type: 'string',
        description: 'The overall sentiment expressed in the customer feedback'
      },
      primary_issue: {
        type: 'string',
        description: 'The core technical or product issue reported by the customer'
      }
    }
  end

  def test_extracts_informal_saas_feedback_with_litote_analysis
    result = ActiveGenie::Extractor.with_litote(@feedback_text, @schema)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    refute_nil result.data[:sentiment]
    refute_nil result.data[:primary_issue]

    refute_empty result.data[:sentiment].to_s
    refute_empty result.data[:primary_issue].to_s

    # Feedback uses litote ("isn't terrible") and expresses clear dissatisfaction — sentiment should be negative
    negative_indicators = %w[negative frustrated dissatisfied unhappy critical mixed]
    assert negative_indicators.any? { |word| result.data[:sentiment].to_s.downcase.include?(word) },
      "Expected negative sentiment indicator, got: #{result.data[:sentiment]}"
  end
end

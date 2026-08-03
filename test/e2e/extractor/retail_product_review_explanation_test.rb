# frozen_string_literal: true

require_relative '../test_helper'

class RetailProductReviewExplanationTest < Minitest::Test
  def test_extract_sentiment_and_topic
    text = "The battery life on this laptop is absolutely atrocious, it barely lasts 2 hours. However, the screen is beautiful."
    schema = {
      overall_sentiment: { type: 'string', description: 'Sentiment of the review (positive, negative, neutral)' },
      main_complaint_topic: { type: 'string', description: 'The main feature complained about' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM needs to synthesize the mixed feelings into an overall negative/mixed sentiment and pinpoint the primary complaint
    assert_match(/negative|mixed/i, data[:overall_sentiment], "Expected sentiment to be negative or mixed, got #{data[:overall_sentiment]}")
    assert_match(/battery/i, data[:main_complaint_topic], "Expected main complaint to be battery, got #{data[:main_complaint_topic]}")
    refute_nil result.reasoning
  end
end

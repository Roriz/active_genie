# frozen_string_literal: true

require_relative '../test_helper'

class RestaurantFoodReviewLitoteTest < Minitest::Test
  def test_extract_litote_sentiment
    text = "To be honest, the food was not bad at all."
    schema = {
      sentiment: { type: 'string', description: 'Overall sentiment (positive, negative, neutral)' }
    }

    result = ActiveGenie::Extractor.with_litote(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM needs to recognize 'not bad at all' as a litote meaning positive or at least decent
    assert_match(/positive|good/i, data[:sentiment], "Expected sentiment to be positive, got #{data[:sentiment]}")
  end
end

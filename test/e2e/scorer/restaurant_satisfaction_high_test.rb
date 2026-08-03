# frozen_string_literal: true

require_relative '../test_helper'

class RestaurantSatisfactionHighTest < Minitest::Test
  def test_perfect_restaurant_review_scores_high
    text = "Best meal of my life! The 5-star service was impeccable and the staff was extremely attentive. The ambiance was incredible and every dish was an absolute delight."
    criteria = "customer satisfaction"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A perfect review with high praise should definitely score highly on customer satisfaction.
    assert result.data >= 70, "Expected customer satisfaction score to be >= 70 for a perfect review, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

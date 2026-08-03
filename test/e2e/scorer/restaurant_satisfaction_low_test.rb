# frozen_string_literal: true

require_relative '../test_helper'

class RestaurantSatisfactionLowTest < Minitest::Test
  def test_terrible_review_scores_low
    text = "Absolutely the worst dining experience. The food was freezing cold, we waited 2 hours just to get water, and I found a hair in my pasta. Never coming back here again."
    criteria = "customer satisfaction"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A review outlining severe service failures and hygiene issues should score very low on satisfaction.
    assert result.data <= 40, "Expected customer satisfaction score to be <= 40 for a terrible review, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

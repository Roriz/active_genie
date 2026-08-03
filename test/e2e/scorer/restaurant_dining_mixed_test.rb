# frozen_string_literal: true

require_relative '../test_helper'

class RestaurantDiningMixedTest < Minitest::Test
  def test_mixed_review_is_numeric
    text = "The steak was cooked to absolute perfection and the flavors were out of this world. However, the waiter was incredibly rude, spilled wine on my shirt, and the music was way too loud."
    criteria = "overall dining experience"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    # WHY: A mixed review with both great and terrible elements should yield a numeric score representing that balance.
    assert_kind_of Numeric, result.data, "Expected a numeric score for a mixed dining experience, got #{result.data.class}"
  end
end

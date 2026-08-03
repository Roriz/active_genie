# frozen_string_literal: true

require_relative '../test_helper'

class DiningRestaurantFreeForAllTest < Minitest::Test
  def test_rank_restaurants
    restaurants = [
      JSON.generate(type: "Michelin Star French", atmosphere: "Elegant, formal", price: "$$$$"),
      JSON.generate(type: "Fast Food Chain", atmosphere: "Casual, quick", price: "$"),
      JSON.generate(type: "Food Truck", atmosphere: "Outdoor, street", price: "$$")
    ]

    result = ActiveGenie::Ranker.by_free_for_all(restaurants, "fine dining for a 10th wedding anniversary")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    assert_equal 3, ranked.length

    michelin = restaurants[0]
    fast_food = restaurants[1]

    # WHY: Fine dining anniversary requires an elegant restaurant, fast food is least appropriate.
    assert_equal michelin, ranked.first, "Expected Michelin Star to be ranked first, got: #{ranked.first}"
    assert_equal fast_food, ranked.last, "Expected Fast Food to be ranked last, got: #{ranked.last}"
  end
end

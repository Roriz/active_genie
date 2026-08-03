# frozen_string_literal: true

require_relative '../test_helper'

class FoodPizzaToppingsFeudTest < Minitest::Test
  def test_pizza_toppings_feud
    theme = "Most popular pizza toppings"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    top_answer = result.data.first.to_s.downcase

    # WHY: Pepperoni or cheese are universally the most popular pizza toppings
    assert(
      top_answer.include?('pepperoni') || top_answer.include?('cheese') || top_answer.include?('margherita'),
      "Expected top answer to contain pepperoni or cheese, but got: #{result.data.inspect}"
    )
  end
end

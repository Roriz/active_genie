# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class BestEvDebateTest < Minitest::Test
  def test_debate_best_ev
    player_a = JSON.generate({ model: "Tesla Model S", price: 80000, range_mi: 400, features: ["autopilot", "electric"] })
    player_b = JSON.generate({ model: "Used Honda Civic", price: 5000, features: ["basic", "gas"] })
    criteria = "Which is the better electric vehicle?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: The Civic is not an EV, so Tesla is the clear winner for the best EV category
    assert_equal player_a, result.data, "Expected Tesla to win as the Civic is not an EV. Got: #{result.data}"

  end
end

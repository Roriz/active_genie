# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class EngagementRingDebateTest < Minitest::Test
  def test_debate_engagement_ring
    player_a = "Diamond ring ($5000, certified real diamond)"
    player_b = "Plastic toy ring ($2, from a vending machine)"
    criteria = "Which is better for a wedding engagement ring?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Diamond ring is obviously the appropriate choice for an engagement ring
    assert_equal player_a, result.data, "Expected Diamond ring to win. Got: #{result.data}"

  end
end

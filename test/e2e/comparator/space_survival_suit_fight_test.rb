# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class SpaceSurvivalSuitFightTest < Minitest::Test
  def test_fight_space_survival
    player_a = "NASA Extravehicular Mobility Unit (Spacesuit): Pressurized, oxygen supply, radiation shielding"
    player_b = "Speedo Swimsuit: Lightweight, aerodynamic, dries quickly"
    criteria = "Which suit is better for surviving outside the ISS in space?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Spacesuit is the only way to survive in space.
    assert_equal player_a, result.data, "Expected NASA Spacesuit to win. Got: #{result.data}"

  end
end

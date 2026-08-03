# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class ArizonaEnergyFightTest < Minitest::Test
  def test_fight_arizona_energy
    player_a = "Solar Panels: Harnesses sunlight to generate electricity"
    player_b = "Wind Turbines: Harnesses wind currents to generate electricity"
    criteria = "Which is better for residential renewable energy in Phoenix, Arizona?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Arizona has abundant sunlight and is desert, making solar the obvious choice over wind for residential
    assert_equal player_a, result.data, "Expected Solar Panels to win in Arizona. Got: #{result.data}"

  end
end

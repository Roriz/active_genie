# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::League::LeagueTest < Minitest::Test
  def test_sharper_geometric_shape
    players = ["Circle", "Triangle", "Square"]
    criteria = "What is more sharper?"
    result = ActiveGenie::League.call(players, criteria)

    assert_equal result.first[:content], "Triangle"
  end
end
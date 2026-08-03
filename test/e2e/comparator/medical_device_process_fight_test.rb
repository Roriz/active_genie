# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class MedicalDeviceProcessFightTest < Minitest::Test
  def test_fight_medical_device
    player_a = "Agile: Rapid iteration, changing requirements, minimal documentation"
    player_b = "Waterfall: Strict phases, heavy upfront design, extensive documentation and verification"
    criteria = "Which process is better for developing highly regulated medical device software?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Medical devices require strict regulatory compliance, extensive docs and verification, making Waterfall much better suited.
    assert_equal player_b, result.data, "Expected Waterfall to win for regulated medical software. Got: #{result.data}"

  end
end

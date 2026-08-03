# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class WeddingCateringFightTest < Minitest::Test
  def test_fight_wedding_catering
    player_a = "Professional Chef: Michelin star, runs a catering business"
    player_b = "College Student: Can make ramen and microwave pizza"
    criteria = "Who is better for catering a 200-person wedding?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Professional chef is obviously better suited for catering a large wedding
    assert_equal player_a, result.data, "Expected Professional Chef to win. Got: #{result.data}"

  end
end

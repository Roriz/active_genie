# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class MobileDevPlatformFightTest < Minitest::Test
  def test_fight_mobile_dev_platform
    player_a = "iPhone / iOS: Walled garden, high revenue per user, unified hardware"
    player_b = "Android: Open ecosystem, massive global market share, diverse hardware"
    criteria = "Which is the best mobile development platform to target first?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Genuinely debatable choice with strong arguments on both sides. Assert valid choice.
    assert_includes [player_a, player_b], result.data, "Expected iOS or Android. Got: #{result.data}"

  end
end

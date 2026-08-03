# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class TrackDayCarFightTest < Minitest::Test
  def test_fight_track_day
    player_a = "Ferrari F40: Lightweight, twin-turbo V8, race-tuned suspension"
    player_b = "Toyota Corolla: Economical, comfortable, reliable daily driver"
    criteria = "Which car is better for track day performance?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Ferrari F40 is objectively better for track performance
    assert_equal player_a, result.data, "Expected Ferrari F40 to win. Got: #{result.data}"

  end
end

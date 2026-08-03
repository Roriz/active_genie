# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class SubtleMenuDebateTest < Minitest::Test
  def test_debate_subtle_menu
    player_a = "Menu A: $15 Burger with regular fries, $5 Shake"
    player_b = "Menu B: $16 Burger with curly fries, $6 Shake"
    criteria = "Which menu offers better value for money?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Subtle difference with no clear objective winner. Assert valid choice.
    assert_includes [player_a, player_b], result.data, "Expected result to be Menu A or B. Got: #{result.data}"

  end
end

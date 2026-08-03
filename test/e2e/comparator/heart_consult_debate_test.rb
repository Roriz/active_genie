# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class HeartConsultDebateTest < Minitest::Test
  def test_debate_heart_consult
    player_a = "Dr. Smith: 20 years experience in general family practice"
    player_b = "Dr. Jones: 3 years experience as a specialized cardiologist surgeon"
    criteria = "Who is better for a heart surgery consultation?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: The cardiologist specialist is the obvious choice for heart surgery over a general practitioner
    assert_equal player_b, result.data, "Expected the cardiologist to win for heart surgery. Got: #{result.data}"

  end
end

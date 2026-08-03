# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class HrBackendRoleDebateTest < Minitest::Test
  def test_debate_backend_role
    player_a = "Senior Python Dev: 10 years experience building scalable backend APIs"
    player_b = "Junior HTML Dev: 1 year experience writing basic markup"
    criteria = "Who is better for a backend role?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Obvious winner based on experience and relevant skills
    assert_equal player_a, result.data, "Expected the Senior Python Dev to win. Got: #{result.data}"

  end
end

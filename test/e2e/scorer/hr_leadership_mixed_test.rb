# frozen_string_literal: true

require_relative '../test_helper'

class HrLeadershipMixedTest < Minitest::Test
  def test_mixed_employee_is_numeric
    text = "Alex is arguably the most technically brilliant engineer on the team and solves our hardest problems. However, he is abrasive, dismisses other people's ideas, and completely lacks empathy during code reviews."
    criteria = "leadership potential"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    # WHY: A technically brilliant but socially abrasive employee has ambiguous leadership potential.
    assert_kind_of Numeric, result.data, "Expected a numeric score for an employee with mixed leadership traits, got #{result.data.class}"
  end
end

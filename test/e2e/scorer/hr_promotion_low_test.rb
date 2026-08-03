# frozen_string_literal: true

require_relative '../test_helper'

class HrPromotionLowTest < Minitest::Test
  def test_poor_employee_scores_low
    text = "John has missed all his major deadlines this year and fails to communicate blockers. Furthermore, there are 3 formal HR complaints regarding his unprofessional behavior in team meetings."
    criteria = "promotion readiness"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: Missing deadlines and having HR complaints indicates extreme unreadiness for promotion.
    assert result.data <= 40, "Expected promotion readiness score to be <= 40 for a poorly performing employee, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

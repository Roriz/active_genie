# frozen_string_literal: true

require_relative '../test_helper'

class HrPromotionHighTest < Minitest::Test
  def test_stellar_employee_scores_high
    text = "Jane has exceeded all her KPIs for four consecutive quarters. She consistently mentors junior developers, architects complex solutions with ease, and takes extreme ownership of critical system outages."
    criteria = "promotion readiness"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: An employee exceeding KPIs and showing leadership is highly ready for promotion.
    assert result.data >= 70, "Expected promotion readiness score to be >= 70 for a stellar employee, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

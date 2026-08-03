# frozen_string_literal: true

require_relative '../test_helper'

class FinanceInvestmentMixedTest < Minitest::Test
  def test_mixed_startup_pitch_is_numeric
    text = "We are targeting a massive $50B total addressable market with a novel AI-driven approach. That said, we currently have zero paying customers, no prototype, and the founding team has never run a business."
    criteria = "investment worthiness"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    # WHY: A startup with a huge market but no traction is a highly ambiguous investment.
    assert_kind_of Numeric, result.data, "Expected a numeric score for a mixed investment pitch, got #{result.data.class}"
  end
end

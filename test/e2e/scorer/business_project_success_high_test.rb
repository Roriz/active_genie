# frozen_string_literal: true

require_relative '../test_helper'

class BusinessProjectSuccessHighTest < Minitest::Test
  def test_perfect_launch_scores_high
    text = "The V2 platform launch was delivered on time and 15% under budget. It exceeded initial sales targets by 200% within the first month and received glowing feedback from enterprise clients with zero reported downtime."
    criteria = "project success"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A launch delivered under budget and over sales targets is extremely successful.
    assert result.data >= 70, "Expected project success score to be >= 70 for a perfect launch, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

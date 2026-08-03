# frozen_string_literal: true

require_relative '../test_helper'

class BusinessProjectSuccessLowTest < Minitest::Test
  def test_failed_launch_scores_low
    text = "The product launch was a disaster. It released 6 months behind schedule and went 300% over the original budget. Since launch, adoption has stalled at a mere 2% of the target user base."
    criteria = "project success"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: Massive delays, budget overruns, and abysmal adoption signify a comprehensively failed project.
    assert result.data <= 40, "Expected project success score to be <= 40 for a failed launch, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

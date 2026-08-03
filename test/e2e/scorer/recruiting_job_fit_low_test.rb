# frozen_string_literal: true

require_relative '../test_helper'

class RecruitingJobFitLowTest < Minitest::Test
  def test_poor_candidate_scores_low
    text = "I am applying for the Senior Ruby Developer role. I have no programming experience, but I am very proficient at Microsoft Excel, data entry, and I'm a fast learner who likes computers."
    criteria = "job fit"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A candidate with zero relevant skills for a senior engineering role should score very low on fit.
    assert result.data <= 40, "Expected job fit score to be <= 40 for a poor candidate, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

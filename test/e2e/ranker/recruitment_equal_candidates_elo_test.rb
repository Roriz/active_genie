# frozen_string_literal: true

require_relative '../test_helper'

class RecruitmentEqualCandidatesEloTest < Minitest::Test
  def test_rank_equal_candidates
    candidates = [
      JSON.generate(name: "Candidate A", experience: "5 years Ruby", degree: "BS CS"),
      JSON.generate(name: "Candidate B", experience: "5.5 years Ruby", degree: "BS CS"),
      JSON.generate(name: "Candidate C", experience: "5 years Ruby", degree: "MS CS")
    ]

    result = ActiveGenie::Ranker.by_elo(candidates, "senior ruby developer role")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    
    # WHY: They are nearly identical. Order doesn't matter, but all 3 must be present.
    assert_equal 3, ranked.length, "Expected all 3 candidates to be ranked, got: #{ranked.length}"
    assert_empty candidates - ranked, "Result should contain all original candidates"
  end
end

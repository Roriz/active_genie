# frozen_string_literal: true

require_relative '../test_helper'

class SoftwareBugScoringTest < Minitest::Test
  def test_score_bug_reports
    bugs = [
      JSON.generate(issue: "Critical data loss on save", impact: "High"),
      JSON.generate(issue: "Minor typo in footer", impact: "Low"),
      JSON.generate(issue: "Moderate UI glitch on mobile", impact: "Medium")
    ]

    result = ActiveGenie::Ranker.by_scoring(bugs, "engineering sprint priority")

    # WHY: by_scoring returns a raw Array, not a Result object
    assert_kind_of Array, result, "Expected result to be an Array, got: #{result.class}"
    refute_empty result, "Expected non-empty array of scores"
    assert_equal 3, result.length, "Expected 3 bugs to be scored"
  end
end

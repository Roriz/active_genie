# frozen_string_literal: true

require_relative '../test_helper'

class HrJobApplicationScoringTest < Minitest::Test
  def test_score_job_applications
    apps = [
      JSON.generate(candidate: "Alice", skills: "Ruby, Rails, Postgres, 10 yrs exp", match: "Perfect"),
      JSON.generate(candidate: "Bob", skills: "Ruby, 2 yrs exp", match: "Partial"),
      JSON.generate(candidate: "Charlie", skills: "Java, Spring, 5 yrs exp", match: "No match")
    ]

    result = ActiveGenie::Ranker.by_scoring(apps, "senior Ruby developer role")

    # WHY: by_scoring returns a raw Array, not a Result object
    assert_kind_of Array, result, "Expected result to be an Array, got: #{result.class}"
    refute_empty result, "Expected non-empty array of scores"
    assert_equal 3, result.length, "Expected 3 applications to be scored"
  end
end

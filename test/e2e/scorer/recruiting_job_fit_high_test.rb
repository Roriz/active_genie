# frozen_string_literal: true

require_relative '../test_helper'

class RecruitingJobFitHighTest < Minitest::Test
  def test_perfect_candidate_scores_high
    text = "I am a Senior Ruby Developer with 10 years of experience building scalable backend architectures in Ruby on Rails. My recent projects involved migrating legacy monoliths to microservices, directly aligning with your job description's core requirements."
    criteria = "job fit"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A cover letter perfectly aligning with a senior Ruby role's requirements should score highly on fit.
    assert result.data >= 70, "Expected job fit score to be >= 70 for a perfect candidate, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

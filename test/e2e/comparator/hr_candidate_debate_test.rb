# frozen_string_literal: true

require_relative '../test_helper'

class HrCandidateDebateTest < Minitest::Test
  def setup
    @payload = load_fixture('hr/candidate_pair.json')
    @candidate_1 = JSON.generate(@payload[:candidate_1])
    @candidate_2 = JSON.generate(@payload[:candidate_2])
    @criteria = "Role: #{@payload[:target_role]}. Evaluate technical stack fit, years of experience, and large-scale infrastructure expertise."
  end

  def test_evaluates_candidates_via_structured_debate
    result = ActiveGenie::Comparator.by_debate(@candidate_1, @candidate_2, @criteria)

    assert_kind_of ActiveGenie::Result, result
    # Jordan Lee (9 yrs, Terraform/K8s/AWS, 500+ node clusters) is the obvious winner for Lead DevOps
    assert_equal @candidate_1, result.data,
      'Expected Jordan Lee (candidate_1) to win the debate for Lead DevOps & Reliability Engineer role'
  end
end

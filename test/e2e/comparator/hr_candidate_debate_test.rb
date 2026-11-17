# frozen_string_literal: true

require_relative '../test_helper'

class HrCandidateDebateTest < Minitest::Test
  def setup
    @payload = load_fixture('hr/candidate_pair.json')
    @candidate_a = JSON.generate(@payload[:candidate_a])
    @candidate_b = JSON.generate(@payload[:candidate_b])
    @criteria = "Role: #{@payload[:target_role]}. Evaluate technical stack fit, years of experience, and large-scale infrastructure expertise."
  end

  def test_evaluates_candidates_via_structured_debate
    result = ActiveGenie::Comparator.by_debate(@candidate_a, @candidate_b, @criteria)

    assert_kind_of ActiveGenie::Result, result
    # Jordan Lee (9 yrs, Terraform/K8s/AWS, 500+ node clusters) is the obvious winner for Lead DevOps
    assert_equal @candidate_a, result.data,
                 'Expected Jordan Lee (candidate_a) to win the debate for Lead DevOps & Reliability Engineer role'
  end
end

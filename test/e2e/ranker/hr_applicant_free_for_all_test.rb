# frozen_string_literal: true

require_relative '../test_helper'

class HrApplicantFreeForAllTest < Minitest::Test
  def setup
    @candidates = [
      { name: 'Alice Chen', experience: '10 yrs', skills: %w[Ruby Go Kubernetes] },
      { name: 'Bob Vance', experience: '2 yrs', skills: %w[HTML CSS] },
      { name: 'Charlie Day', experience: '6 yrs', skills: %w[Python Docker AWS] }
    ].map { |c| JSON.generate(c) }
    @criteria = 'Rank applicants for a Senior Staff Infrastructure Engineer role based on experience and cloud skills.'
  end

  def test_ranks_hr_applicants_via_free_for_all
    result = ActiveGenie::Ranker.by_free_for_all(@candidates, @criteria)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Array, result.data
    assert_equal @candidates.size, result.data.size

    # Alice (10 yrs, Ruby/Go/Kubernetes) is the obvious best fit for Senior Staff Infrastructure Engineer
    assert_includes result.data.first, 'Alice Chen',
                    "Expected strongest candidate (Alice Chen) ranked first, got: #{result.data.first[0..50]}"
    # Bob (2 yrs, HTML/CSS) is the obvious weakest fit
    assert_includes result.data.last, 'Bob Vance',
                    "Expected weakest candidate (Bob Vance) ranked last, got: #{result.data.last[0..50]}"
  end
end

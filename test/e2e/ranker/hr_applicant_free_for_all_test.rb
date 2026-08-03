# frozen_string_literal: true

require_relative '../test_helper'

class HrApplicantFreeForAllTest < Minitest::Test
  def setup
    @candidates = [
      { name: 'Alice Chen', experience: '10 yrs', skills: ['Ruby', 'Go', 'Kubernetes'] },
      { name: 'Bob Vance', experience: '2 yrs', skills: ['HTML', 'CSS'] },
      { name: 'Charlie Day', experience: '6 yrs', skills: ['Python', 'Docker', 'AWS'] }
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
    assert result.data.first.include?('Alice Chen'),
      "Expected strongest candidate (Alice Chen) ranked first, got: #{result.data.first[0..50]}"
    # Bob (2 yrs, HTML/CSS) is the obvious weakest fit
    assert result.data.last.include?('Bob Vance'),
      "Expected weakest candidate (Bob Vance) ranked last, got: #{result.data.last[0..50]}"
  end
end

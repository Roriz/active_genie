# frozen_string_literal: true

require_relative '../test_helper'

class FintechCreditScoringTest < Minitest::Test
  def setup
    @payload = load_fixture('fintech/credit_application.json')
    @text = JSON.generate(@payload[:applicant])
    @criteria = 'Evaluate creditworthiness and financial stability based on income, debt ratio, and credit history.'
    @juries = ['Senior Credit Risk Officer', 'Underwriting Auditor']
  end

  def test_scores_fintech_credit_application_with_jury_bench
    result = ActiveGenie::Scorer.by_jury_bench(@text, @criteria, @juries)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Numeric, result.data
    # Strong applicant (745 credit score, 0 late payments, stable employment) should score well
    assert_operator result.data, :>=, 50,
      "Expected creditworthy score (>=50) for strong applicant, got: #{result.data}"

    refute_nil result.reasoning
  end
end

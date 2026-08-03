# frozen_string_literal: true

require_relative '../test_helper'

class FintechRiskExtractionTest < Minitest::Test
  def setup
    @loan_payload = load_fixture('fintech/loan_application.json')
    @text = JSON.generate(@loan_payload)
    @schema = {
      risk_level: {
        type: 'string',
        enum: %w[low medium high],
        description: 'Overall risk assessment level for the commercial loan application'
      },
      annual_revenue_usd: {
        type: 'number',
        description: 'The annual revenue of the business applicant in USD'
      },
      key_strengths: {
        type: 'string',
        description: 'Primary positive financial indicators from the bank statement'
      }
    }
  end

  def test_extracts_fintech_loan_risk_with_explanation
    result = ActiveGenie::Extractor.with_explanation(@text, @schema)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data[:risk_level]
    refute_nil result.data[:annual_revenue_usd]

    # Verify semantic boundary constraints
    assert_includes %w[low medium high], result.data[:risk_level].to_s.downcase
    assert_operator result.data[:annual_revenue_usd].to_f, :>=, 1_000_000
  end
end

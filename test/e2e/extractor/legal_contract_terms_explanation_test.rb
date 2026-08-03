# frozen_string_literal: true

require_relative '../test_helper'

class LegalContractTermsExplanationTest < Minitest::Test
  def test_extract_contract_value_and_terms
    text = "Client agrees to pay the sum of fifty-two thousand five hundred dollars over the course of a year. Payment is due net 30 from the receipt of the invoice."
    schema = {
      contract_value: { type: 'number', description: 'Total numerical value of the contract' },
      payment_terms: { type: 'string', description: 'Payment terms' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: The LLM must convert worded currency into a numeric value and extract the payment term accurately
    assert_equal 52500, data[:contract_value], "Expected contract value to be 52500, got #{data[:contract_value]}"
    assert_match(/net 30/i, data[:payment_terms], "Expected payment terms to include 'net 30', got #{data[:payment_terms]}")
    refute_nil result.reasoning
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class FinanceCryptoFraudJuriesTest < Minitest::Test
  def test_crypto_fraud_juries
    text = "Investigating an international syndicate laundering money through decentralized finance protocols"
    criteria = "Evaluate regulatory violations and blockchain transaction traceability"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Cross-border crypto fraud requires both legal/financial regulation expertise and technical blockchain knowledge
    has_legal = juries.any? { |j| j.include?('legal') || j.include?('law') || j.include?('regulat') || j.include?('finance') || j.include?('investigator') }
    has_crypto = juries.any? { |j| j.include?('crypto') || j.include?('blockchain') || j.include?('cyber') }

    assert(
      has_legal && has_crypto,
      "Expected juries to include both legal/financial and crypto/blockchain experts, but got: #{result.data.inspect}"
    )
  end
end

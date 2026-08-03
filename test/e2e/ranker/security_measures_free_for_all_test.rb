# frozen_string_literal: true

require_relative '../test_helper'

class SecurityMeasuresFreeForAllTest < Minitest::Test
  def test_rank_security_measures
    measures = [
      JSON.generate(type: "MFA + Encryption + Audit Logs", security_level: "High"),
      JSON.generate(type: "Password only", security_level: "Low"),
      JSON.generate(type: "No Auth", security_level: "None")
    ]

    result = ActiveGenie::Ranker.by_free_for_all(measures, "enterprise API security")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    assert_equal 3, ranked.length

    best = measures[0]
    worst = measures[2]

    # WHY: Enterprise APIs require strict security (MFA), not \"No Auth\".
    assert_equal best, ranked.first, "Expected MFA to be ranked first, got: #{ranked.first}"
    assert_equal worst, ranked.last, "Expected No Auth to be ranked last, got: #{ranked.last}"
  end
end

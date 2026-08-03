# frozen_string_literal: true

require_relative '../test_helper'

class TechAiHiringBiasJuriesTest < Minitest::Test
  def test_ai_hiring_bias_juries
    text = "Evaluating a new machine learning resume screener that disproportionately rejects female candidates"
    criteria = "Evaluate algorithmic fairness and ethical implications"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Evaluating AI bias requires ML experts or ethicists to understand the algorithmic and societal impacts
    has_expert = juries.any? { |j| j.include?('ethic') || j.include?('ai') || j.include?('ml') || j.include?('data') || j.include?('machine learning') }

    assert(
      has_expert,
      "Expected juries to include ethics or AI/ML expert, but got: #{result.data.inspect}"
    )
  end
end

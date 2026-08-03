# frozen_string_literal: true

require_relative '../test_helper'

class HealthWorkplaceErgonomicsJuriesTest < Minitest::Test
  def test_workplace_ergonomics_juries
    text = "Evaluating a factory worker's claim of chronic back pain resulting from repetitive lifting"
    criteria = "Evaluate occupational hazard and workplace safety protocols"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Ergonomic injuries require specialists in occupational health or ergonomics
    has_expert = juries.any? { |j| j.include?('occupational') || j.include?('health') || j.include?('ergonomic') || j.include?('medical') }

    assert(
      has_expert,
      "Expected juries to include occupational health or ergonomic expert, but got: #{result.data.inspect}"
    )
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class EnvironmentalOilSpillJuriesTest < Minitest::Test
  def test_oil_spill_juries
    text = "Assessing the ecological damage and cleanup efforts following a coastal crude oil spill"
    criteria = "Evaluate environmental impact and remediation effectiveness"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Oil spill evaluation requires specific scientific expertise in environmental impact
    has_expert = juries.any? { |j| j.include?('environment') || j.include?('ecologist') || j.include?('biologist') || j.include?('scientist') }

    assert(
      has_expert,
      "Expected juries to include an environmental scientist or ecologist, but got: #{result.data.inspect}"
    )
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class HealthFoodSafetyJuriesTest < Minitest::Test
  def test_food_safety_juries
    text = "Investigating an outbreak of E. coli linked to a local restaurant chain's produce supplier"
    criteria = "Evaluate health code compliance and contamination source"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Food safety violations specifically require health inspectors or food safety experts
    has_inspector = juries.any? { |j| j.include?('health') || j.include?('inspector') || j.include?('food') || j.include?('safety') }

    assert(
      has_inspector,
      "Expected juries to include a food safety/health inspector type, but got: #{result.data.inspect}"
    )
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class LegalAutonomousVehicleJuriesTest < Minitest::Test
  def test_autonomous_vehicle_juries
    text = "Determining liability in a multi-vehicle crash caused by an autonomous taxi turning left"
    criteria = "Evaluate technical fault and legal liability"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Needs both technical knowledge of autonomous systems and legal knowledge of liability
    has_engineer = juries.any? { |j| j.include?('engineer') || j.include?('ai') || j.include?('autonomous') || j.include?('automotive') }

    assert(
      has_engineer,
      "Expected juries to include automotive engineer or AI expert, but got: #{result.data.inspect}"
    )
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class MedicalMalpracticeJuriesTest < Minitest::Test
  def test_medical_malpractice_juries
    text = "Reviewing patient records to determine if surgical protocol was followed correctly"
    criteria = "Evaluate medical procedure and standard of care"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: A medical malpractice jury requires a medical professional to establish standard of care
    has_medical = juries.any? { |j| j.include?('doctor') || j.include?('physician') || j.include?('surgeon') || j.include?('medical') }

    assert(
      has_medical,
      "Expected juries to include a medical doctor or physician, but got: #{result.data.inspect}"
    )
  end
end

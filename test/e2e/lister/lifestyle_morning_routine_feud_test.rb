# frozen_string_literal: true

require_relative '../test_helper'

class LifestyleMorningRoutineFeudTest < Minitest::Test
  def test_morning_routine_feud
    theme = "Things people do first thing in the morning"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: Morning routines almost universally include coffee, checking phone, bathroom, or alarm
    has_expected = answers.any? { |a| a.include?('coffee') || a.include?('alarm') || a.include?('bathroom') || a.include?('phone') || a.include?('teeth') }
    assert(
      has_expected,
      "Expected list to include alarm, coffee, or bathroom related activities, but got: #{result.data.inspect}"
    )
  end
end

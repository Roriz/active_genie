# frozen_string_literal: true

require_relative '../test_helper'

class LifestyleNewYearsResolutionsFeudTest < Minitest::Test
  def test_new_years_resolutions_feud
    theme = "Most common New Year's resolutions"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: Health, exercise, and weight loss dominate new year's resolutions
    has_health = answers.any? { |a| a.include?('weight') || a.include?('exercise') || a.include?('gym') || a.include?('health') || a.include?('diet') }

    assert(
      has_health,
      "Expected list to include exercise, fitness, weight, or health related items, but got: #{result.data.inspect}"
    )
  end
end

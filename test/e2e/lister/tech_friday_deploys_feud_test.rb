# frozen_string_literal: true

require_relative '../test_helper'

class TechFridayDeploysFeudTest < Minitest::Test
  def test_friday_deploys_feud
    theme = "Reasons a software deploy fails on Friday"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: Friday deploy fails are notoriously caused by untested code, rushing, or human error late in the day
    has_expected = answers.any? { |a| a.include?('test') || a.include?('rush') || a.include?('human error') || a.include?('tired') || a.include?('bug') || a.include?('untested') }

    assert(
      has_expected,
      "Expected list to include testing, rushing, or human error items, but got: #{result.data.inspect}"
    )
  end
end

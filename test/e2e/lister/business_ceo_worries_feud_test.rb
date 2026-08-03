# frozen_string_literal: true

require_relative '../test_helper'

class BusinessCeoWorriesFeudTest < Minitest::Test
  def test_ceo_worries_feud
    theme = "Things a CEO worries about at 3am"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: CEOs worry about critical business threats: money (revenue/profit), competition, or staff (layoffs/retention)
    has_business = answers.any? { |a| a.include?('money') || a.include?('revenue') || a.include?('competition') || a.include?('layoff') || a.include?('profit') || a.include?('market') }

    assert(
      has_business,
      "Expected list to be business-relevant (revenue, competition, layoffs, etc), but got: #{result.data.inspect}"
    )
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class CareerQuittingReasonsFeudTest < Minitest::Test
  def test_quitting_reasons_feud
    theme = "Reasons people quit their jobs"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: Pay and bad management are the primary drivers for quitting a job
    has_pay = answers.any? { |a| a.include?('salary') || a.include?('pay') || a.include?('money') || a.include?('compensation') }
    has_boss = answers.any? { |a| a.include?('boss') || a.include?('management') || a.include?('manager') }

    assert(
      has_pay || has_boss,
      "Expected list to include salary/pay or management/boss related items, but got: #{result.data.inspect}"
    )
  end
end

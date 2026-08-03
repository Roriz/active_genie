# frozen_string_literal: true

require_relative '../test_helper'

class HealthtechTriageScoringTest < Minitest::Test
  def setup
    @payload = load_fixture('healthtech/patient_triage.json')
    @text = JSON.generate(@payload)
    @criteria = 'Evaluate medical urgency and triage urgency score (0-100) for emergency department admission.'
  end

  def test_scores_healthtech_patient_triage_urgency
    result = ActiveGenie::Scorer.by_jury_bench(@text, @criteria)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Numeric, result.data
    # Textbook acute MI presentation should triage as high urgency
    assert_operator result.data, :>=, 60,
      "Expected high urgency score (>=60) for acute MI presentation, got: #{result.data}"

    refute_nil result.reasoning
  end
end

# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::Scoring::TerribleTest < Minitest::Test
  def test_evaluate_incident_report
    result = ActiveGenie::Scoring::Basic.call('WARNING!!! URGENT!!! System totally broken!!! Nothing works!!! Fix ASAP!!!', 'Evaluate incident report quality and professionalism', ['system_reliability_engineer'])

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_completeness
    result = ActiveGenie::Scoring::Basic.call('Section 3.4: Data must secure. Implement good security. Make system fast.', 'Evaluate completeness and clarity of technical requirements', ['system_architect'])

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end
end
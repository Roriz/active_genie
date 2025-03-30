# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::Scoring::BadScoresTest < Minitest::Test
  def test_evaluate_bug_report
    result = ActiveGenie::Scoring::Basic.call('idk the app keeps crashing sometimes when i try to do stuff. maybe fix it?', 'Evaluate bug report quality and actionability', ['qa_engineer'])

    assert_equal result['final_score'] >= 10, true, "Expected to be at greater than 10, but was #{result['final_score']}, because: #{result['final_reasoning']}"
    assert_equal result['final_score'] <= 50, true, "Expected to be at less than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_technical_accuracy
    result = ActiveGenie::Scoring::Basic.call('Our new product uses AI and blockchain technology with quantum computing capabilities to revolutionize the industry with cutting-edge solutions that leverage synergistic paradigms.', 'Evaluate technical accuracy and marketing claims', ['technical_writer'])

    assert_equal result['final_score'] >= 10, true, "Expected to be at greater than 10, but was #{result['final_score']}, because: #{result['final_reasoning']}"
    assert_equal result['final_score'] <= 50, true, "Expected to be at less than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_code_review_feedback
    result = ActiveGenie::Scoring::Basic.call('The code has bugs. I tried to fix them but they are still there. The performance is also not good, we should optimize it.', 'Evaluate code review feedback quality', ['senior_software_engineer'])

    assert_equal result['final_score'] >= 10, true, "Expected to be at greater than 10, but was #{result['final_score']}, because: #{result['final_reasoning']}"
    assert_equal result['final_score'] <= 50, true, "Expected to be at less than 50, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end
end
# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::Scoring::TerribleTest < Minitest::Test
  def test_evaluate_incident_report
    result = ActiveGenie::Scoring.call('WARNING!!! URGENT!!! System totally broken!!! Nothing works!!! Fix ASAP!!!', 'Evaluate incident report quality and professionalism', ['system_reliability_engineer'])

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_evaluate_completeness
    result = ActiveGenie::Scoring.call('Section 3.4: Data must secure. Implement good security. Make system fast.', 'Evaluate completeness and clarity of technical requirements', ['system_architect'])

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_marketplace_product_quality
    product_description = <<~PRODUCT_DESCRIPTION
      I found this in my garage. Not sure what it is, but it looks kinda cool. Might be rare?
      Or not. Some scratches and stuff, but it still works… I think. Selling as-is, no refunds.
      Buy now or send me an offer. Don't ask too many questions, I don’t know much about it!
    PRODUCT_DESCRIPTION
    criteria = <<~CRITERIA
      item description should provide clear details about what is being sold, including the brand, model, size, color, and key features so buyers know exactly what they’re getting. It should honestly state the condition, mentioning if it’s new, like new, or used, and highlight any defects or wear to build trust. The description should confirm the functionality, whether it works perfectly or has minor issues. If any accessories, manuals, or packaging are included, that should be mentioned. Shipping details should specify the method, cost, and estimated delivery time, and the return policy should be clear. The language should be concise, professional, and engaging, making it easy for buyers to read and understand.
    CRITERIA
    result = ActiveGenie::Scoring.call(product_description, criteria, ['ebay_seller_moderator', 'ebay_product_analyzer'])

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end

  def test_technical_difficulty_of_jira_task
    jira_task = <<~JIRA_TASK
      Update the copyright text in the footer of the e-commerce platform to reflect the current year.
    JIRA_TASK
    criteria = <<~CRITERIA
      Analyze technical difficulty of implementing the feature.
      The feature will be built from scratch. Use high scores for the most complex tasks and low scores for the simple tasks
    CRITERIA
    reviewers = [
      'senior_software_engineer', 'architect_engineer',
      'devops_engineer', 'software_engineer'
    ]

    result = ActiveGenie::Scoring.call(jira_task, criteria, reviewers)

    assert_equal result['final_score'] <= 20, true, "Expected to be at less than 20, but was #{result['final_score']}, because: #{result['final_reasoning']}"
  end
end
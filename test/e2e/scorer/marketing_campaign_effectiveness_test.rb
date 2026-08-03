# frozen_string_literal: true

require_relative '../test_helper'

class MarketingCampaignEffectivenessTest < Minitest::Test
  def test_viral_campaign_with_custom_juries
    text = "The new social media campaign went completely viral, driving a 500% increase in organic traffic and returning an incredible 12x ROI on our ad spend, significantly boosting overall brand awareness."
    criteria = "viral campaign with high ROI"
    juries = ['CMO', 'Growth Hacker', 'Brand Strategist']

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria, juries)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A viral campaign yielding massive traffic and ROI is highly effective and should satisfy top marketing experts.
    assert result.data >= 60, "Expected marketing campaign effectiveness score to be >= 60, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

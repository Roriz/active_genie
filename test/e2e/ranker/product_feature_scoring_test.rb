# frozen_string_literal: true

require_relative '../test_helper'

class ProductFeatureScoringTest < Minitest::Test
  def test_score_feature_requests
    features = [
      JSON.generate(feature: "SSO Integration", revenue_impact: "High"),
      JSON.generate(feature: "Dark Mode", revenue_impact: "Low"),
      JSON.generate(feature: "Export to CSV", revenue_impact: "Medium"),
      JSON.generate(feature: "Custom Avatars", revenue_impact: "Low")
    ]

    result = ActiveGenie::Ranker.by_scoring(features, "roadmap prioritization for enterprise clients")

    # WHY: by_scoring returns a raw Array, not a Result object
    assert_kind_of Array, result, "Expected result to be an Array, got: #{result.class}"
    refute_empty result, "Expected non-empty array of scores"
    assert_equal 4, result.length, "Expected 4 features to be scored"
  end
end

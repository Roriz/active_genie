# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class MlStartupCloudDebateTest < Minitest::Test
  def test_debate_ml_startup
    player_a = "AWS: Broadest set of general services and huge market share"
    player_b = "GCP: Superior data processing and machine learning managed services"
    criteria = "Which cloud provider is better for an ML-focused startup?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Ambiguous - either can be justified. Assert valid result.
    assert_includes [player_a, player_b], result.data, "Expected result to be either AWS or GCP. Got: #{result.data}"

  end
end

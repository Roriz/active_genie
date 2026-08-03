# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class EcommerceInfrastructureDebateTest < Minitest::Test
  def test_debate_ecommerce_infrastructure
    player_a = "Kubernetes: Highly customizable, great for persistent complex orchestration, fixed base costs"
    player_b = "Serverless: Auto-scales to zero, handles unpredictable spikes well, pay-per-execution"
    criteria = "Which is better for unpredictable traffic in e-commerce?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Both have valid arguments for handling traffic (K8s scaling vs Serverless auto-scale). Assert valid choice.
    assert_includes [player_a, player_b], result.data, "Expected K8s or Serverless. Got: #{result.data}"

  end
end

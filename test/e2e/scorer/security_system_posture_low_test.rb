# frozen_string_literal: true

require_relative '../test_helper'

class SecuritySystemPostureLowTest < Minitest::Test
  def test_vulnerable_audit_scores_low
    text = "The application is highly vulnerable. We discovered trivial SQL injections, persistent XSS on the homepage, and hardcoded database credentials committed directly to the public GitHub repository."
    criteria = "system security posture"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: Multiple critical vulnerabilities including exposed credentials mean a terrible security posture.
    assert result.data <= 40, "Expected security posture score to be <= 40 for a vulnerable system, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

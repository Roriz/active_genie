# frozen_string_literal: true

require_relative '../test_helper'

class SecuritySystemPostureHighTest < Minitest::Test
  def test_flawless_audit_scores_high
    text = "The comprehensive security audit revealed zero critical, high, or medium vulnerabilities. All data is encrypted at rest and in transit, IAM policies follow strict least privilege, and no exposed secrets were found during penetration testing."
    criteria = "system security posture"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: Zero vulnerabilities and strict policies should yield a high security posture score.
    assert result.data >= 70, "Expected security posture score to be >= 70 for a flawless audit, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

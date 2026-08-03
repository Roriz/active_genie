# frozen_string_literal: true

require_relative '../test_helper'

class EngineeringCodeQualityTest < Minitest::Test
  def test_clean_code_with_custom_juries
    text = "The pull request refactors the authentication module perfectly. It features 100% test coverage, follows SOLID principles, removes obsolete dependencies, and ensures no OWASP Top 10 vulnerabilities are present."
    criteria = "clean, well-tested code"
    juries = ['Staff Engineer', 'Security Architect']

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria, juries)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: Clean, secure, and highly tested code should satisfy both an architect and an engineer.
    assert result.data >= 60, "Expected code review quality score to be >= 60, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

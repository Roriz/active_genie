# frozen_string_literal: true

require_relative '../test_helper'

class LegalBriefQualityTest < Minitest::Test
  def test_well_written_legal_brief_with_custom_juries
    text = "The brief is meticulously researched, citing relevant Supreme Court precedents directly addressing the constitutional questions. The arguments are structurally sound, compelling, and free of logical fallacies."
    criteria = "well-written brief"
    juries = ['Constitutional Law Professor', 'Supreme Court Clerk']

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria, juries)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A heavily researched, well-argued brief should pass the threshold of expert juries.
    assert result.data >= 50, "Expected legal brief quality score to be >= 50, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

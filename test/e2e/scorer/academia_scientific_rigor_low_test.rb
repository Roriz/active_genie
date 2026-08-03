# frozen_string_literal: true

require_relative '../test_helper'

class AcademiaScientificRigorLowTest < Minitest::Test
  def test_poor_research_scores_low
    text = "We observed 5 people we found on the street and concluded that eating apples causes baldness. There was no control group, no defined methodology, and this paper has not been reviewed by any peers."
    criteria = "scientific rigor"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A tiny sample size with no methodology or peer review lacks any scientific rigor.
    assert result.data <= 40, "Expected scientific rigor score to be <= 40 for poor research, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

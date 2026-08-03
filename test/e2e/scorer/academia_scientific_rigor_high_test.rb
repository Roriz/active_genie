# frozen_string_literal: true

require_relative '../test_helper'

class AcademiaScientificRigorHighTest < Minitest::Test
  def test_rigorous_research_scores_high
    text = "This double-blind, randomized controlled trial involved over 10,000 participants across 50 countries. The methodology is transparent, p-values are highly significant, and the study has been heavily peer-reviewed by leading experts in the field."
    criteria = "scientific rigor"

    result = ActiveGenie::Scorer.by_jury_bench(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    assert_kind_of Numeric, result.data
    # WHY: A paper with strong methodology, huge sample, and peer review indicates high scientific rigor.
    assert result.data >= 70, "Expected scientific rigor score to be >= 70 for a rigorous paper, got #{result.data}\nReasoning: #{result.reasoning}"
  end
end

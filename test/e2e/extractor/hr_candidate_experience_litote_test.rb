# frozen_string_literal: true

require_relative '../test_helper'

class HrCandidateExperienceLitoteTest < Minitest::Test
  def test_extract_litote_experience
    text = "She is not unfamiliar with the challenges of leadership."
    schema = {
      assessment: { type: 'string', description: 'Assessment of candidate experience level' }
    }

    result = ActiveGenie::Extractor.with_litote(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM should resolve 'not unfamiliar' into having familiarity or experience
    assert_match(/experienced|familiar|knowledgeable/i, data[:assessment], "Expected assessment to indicate experience/familiarity, got #{data[:assessment]}")
  end
end

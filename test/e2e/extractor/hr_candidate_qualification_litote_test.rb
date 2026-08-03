# frozen_string_literal: true

require_relative '../test_helper'

class HrCandidateQualificationLitoteTest < Minitest::Test
  def test_extract_litote_qualification
    text = "Given their background, I wouldn't say the candidate is unqualified."
    schema = {
      qualification_status: { type: 'string', description: 'Status of candidate qualification' }
    }

    result = ActiveGenie::Extractor.with_litote(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM needs to understand double negative 'would not say ... unqualified' -> they are qualified/suitable
    assert_match(/qualified|suitable|competent/i, data[:qualification_status], "Expected qualification status to be qualified/suitable, got #{data[:qualification_status]}")
  end
end

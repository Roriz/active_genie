# frozen_string_literal: true

require_relative '../test_helper'

class TechSoftwareQualityLitoteTest < Minitest::Test
  def test_extract_litote_quality
    text = "The software is not without its flaws."
    schema = {
      quality_assessment: { type: 'string', description: 'Assessment of software quality' }
    }

    result = ActiveGenie::Extractor.with_litote(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM should resolve 'not without its flaws' into meaning it has flaws/is imperfect
    assert_match(/flawed|imperfect|mixed|moderate|has flaws/i, data[:quality_assessment], "Expected quality assessment to indicate mixed/moderate quality or having flaws, got #{data[:quality_assessment]}")
  end
end

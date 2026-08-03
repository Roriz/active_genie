# frozen_string_literal: true

require_relative '../test_helper'

class BusinessQuarterlyEmailLitoteTest < Minitest::Test
  def test_extract_complex_litotes
    text = "The quarterly results were not insignificant, and the team's effort was not unnoticed."
    schema = {
      performance: { type: 'string', description: 'Assessment of quarterly results performance' },
      recognition: { type: 'string', description: 'Level of recognition for the team' }
    }

    result = ActiveGenie::Extractor.with_litote(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM needs to resolve multiple litotes in one sentence into positive affirmations
    assert_match(/significant|good|strong|positive/i, data[:performance], "Expected performance to be significant/good, got #{data[:performance]}")
    assert_match(/noticed|recognized|appreciated|acknowledged/i, data[:recognition], "Expected recognition to be noticed/acknowledged, got #{data[:recognition]}")
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class FinanceAnalystReportExplanationTest < Minitest::Test
  def test_extract_investment_recommendation
    text = "While the company has shown strong Q3 revenue growth and expanded its margins, the macroeconomic headwinds and looming regulatory scrutiny suggest the current stock price is fully valued. We advise investors to maintain their current positions without adding to them at this time."
    schema = {
      investment_recommendation: { type: 'string', description: 'Recommendation (must be one of: buy, hold, sell)' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM must deduce the correct enum value ('hold') from the nuanced prose ('maintain current positions without adding')
    assert_match(/^hold$/i, data[:investment_recommendation].to_s.strip, "Expected recommendation to be strictly 'hold', got #{data[:investment_recommendation]}")
    refute_nil result.reasoning
  end
end

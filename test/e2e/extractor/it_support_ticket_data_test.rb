# frozen_string_literal: true

require_relative '../test_helper'

class ItSupportTicketDataTest < Minitest::Test
  def test_extract_ticket_metadata
    text = "The server is ON FIRE! Well not really but it's completely down and our entire accounting division can't process payroll right now. Need this fixed ASAP!"
    schema = {
      is_urgent: { type: 'boolean', description: 'Whether the issue requires immediate attention' },
      department: { type: 'string', description: 'The department experiencing the issue' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    # Extractor.data returns string keys; normalize before symbol access.
    data = result.data.transform_keys(&:to_sym)
    # WHY: The LLM needs to deduce boolean urgency from tone/context, and extract the department
    assert_equal true, data[:is_urgent], "Expected is_urgent to be true, got #{data[:is_urgent]}"
    assert_match(/accounting/i, data[:department].to_s, "Expected department to be accounting, got #{data[:department]}")
  end
end

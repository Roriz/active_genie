# frozen_string_literal: true

require_relative '../test_helper'

class AdminMeetingNotesDataTest < Minitest::Test
  def test_extract_meeting_details
    text = "We met up around Tuesday the 14th of November at the main HQ on 5th avenue. Sarah, Mike, and that new guy from sales (Dave?) were there."
    schema = {
      date: { type: 'string', description: 'Date of the meeting' },
      location: { type: 'string', description: 'Location of the meeting' },
      attendees: { type: 'array', description: 'List of people who attended' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: The LLM must handle messy conversational text and extract structured information
    assert_match(/November 14|14th of November|Tuesday the 14th/i, data[:date].to_s, "Expected date to match loosely, got #{data[:date]}")
    assert_match(/HQ|5th avenue/i, data[:location].to_s, "Expected location to match, got #{data[:location]}")
    assert_includes data[:attendees].map(&:to_s).join(' '), "Sarah", "Expected attendees to include Sarah, got #{data[:attendees]}"
  end
end

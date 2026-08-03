# frozen_string_literal: true

require_relative '../test_helper'

class ContactBusinessCardDataTest < Minitest::Test
  def test_extract_business_card_info
    text = "John Doe\nVP of Engineering\njohn.doe@example.com\nCell: 555-019-8472\nTechCorp Inc."
    schema = {
      name: { type: 'string', description: 'Full name of the person' },
      email: { type: 'string', description: 'Email address' },
      phone: { type: 'string', description: 'Phone number' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: An easy extraction should pinpoint exact fields accurately
    assert_equal "John Doe", data[:name], "Expected exact name, got #{data[:name]}"
    assert_equal "john.doe@example.com", data[:email], "Expected exact email, got #{data[:email]}"
    assert_match(/555-019-8472/, data[:phone], "Expected phone number to match, got #{data[:phone]}")
  end
end

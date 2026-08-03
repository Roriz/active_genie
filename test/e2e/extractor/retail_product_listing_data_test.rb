# frozen_string_literal: true

require_relative '../test_helper'

class RetailProductListingDataTest < Minitest::Test
  def test_extract_product_details
    text = "Buy the new SuperGamer X100 Pro headset. Only $149.99! Perfect for Electronics > Audio > Gaming peripherals."
    schema = {
      product_name: { type: 'string', description: 'Name of the product' },
      price: { type: 'number', description: 'Price of the product without currency symbol' },
      category: { type: 'string', description: 'Primary category of the product' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    # Extractor.data returns string keys; normalize before symbol access.
    data = result.data.transform_keys(&:to_sym)
    # WHY: The LLM should extract explicit facts with formatting correctly
    assert_match(/SuperGamer X100 Pro/, data[:product_name], "Expected product name to match, got #{data[:product_name]}")
    assert_equal 149.99, data[:price].to_f, "Expected exact price, got #{data[:price]}"
    assert_match(/Electronics|Audio|Gaming/i, data[:category], "Expected category to match, got #{data[:category]}")
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class MeteorologyWeatherReportDataTest < Minitest::Test
  def test_extract_numerical_weather_data
    text = "It's scorching hot outside today, reaching a peak of ninety-five degrees Fahrenheit. The air is pretty dry at around thirty percent moisture, and we're seeing gentle breezes blowing east at 12 mph."
    schema = {
      temperature: { type: 'number', description: 'Temperature in Fahrenheit' },
      humidity: { type: 'number', description: 'Humidity percentage' },
      wind_speed: { type: 'number', description: 'Wind speed in mph' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: The LLM needs to convert worded numbers ('ninety-five', 'thirty') into numerical values
    assert_equal 95, data[:temperature], "Expected temperature to be 95, got #{data[:temperature]}"
    assert_equal 30, data[:humidity], "Expected humidity to be 30, got #{data[:humidity]}"
    assert_equal 12, data[:wind_speed], "Expected wind speed to be 12, got #{data[:wind_speed]}"
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

class TransportationTrafficJamsFeudTest < Minitest::Test
  def test_traffic_jams_feud
    theme = "Things that cause traffic jams"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    top_answer = result.data.first.to_s.downcase

    # WHY: Accidents, construction, and rush hour are overwhelmingly the most common reasons for traffic jams
    assert(
      top_answer.include?('accident') || top_answer.include?('construction') || top_answer.include?('rush hour') || top_answer.include?('crash'),
      "Expected top answer to relate to accidents, construction, or rush hour, but got: #{result.data.inspect}"
    )
  end
end

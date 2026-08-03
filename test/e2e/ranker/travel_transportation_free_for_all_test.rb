# frozen_string_literal: true

require_relative '../test_helper'

class TravelTransportationFreeForAllTest < Minitest::Test
  def test_rank_transportation
    transports = [
      JSON.generate(mode: "Plane", time: "1.5 hours"),
      JSON.generate(mode: "Train", time: "3 hours"),
      JSON.generate(mode: "Bus", time: "5 hours"),
      JSON.generate(mode: "Car", time: "4.5 hours")
    ]

    result = ActiveGenie::Ranker.by_free_for_all(transports, "NYC to DC business trip, 3hr meeting at 2pm")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    assert_equal 4, ranked.length

    plane = transports[0]
    train = transports[1]

    # WHY: A business trip needs fast, reliable transit like a plane or train, over a bus.
    top_modes = [plane, train]
    assert_includes top_modes, ranked.first, "Expected Plane or Train to be ranked first, got: #{ranked.first}"
  end
end

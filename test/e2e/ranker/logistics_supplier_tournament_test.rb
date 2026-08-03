# frozen_string_literal: true

require_relative '../test_helper'

class LogisticsSupplierTournamentTest < Minitest::Test
  def setup
    @payload = load_fixture('logistics/carrier_bids.json')
    @players = @payload[:bids].map { |b| JSON.generate(b) }
    @criteria = "Shipment: #{@payload[:cargo_type]} from #{@payload[:origin]} to #{@payload[:destination]}. Priority: Temperature monitoring guarantee, then speed, then price."
  end

  def test_ranks_logistics_suppliers_via_tournament
    result = ActiveGenie::Ranker.by_tournament(@players, @criteria)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Array, result.data
    assert_equal @players.size, result.data.size

    # ColdChain Express has temp monitoring + fastest transit — best match for criteria priority
    assert result.data.first.include?('ColdChain Express'),
      "Expected ColdChain Express ranked first, got: #{result.data.first[0..50]}"
    # Speedy Haulers lacks temperature monitoring — worst match for refrigerated medical supplies
    assert result.data.last.include?('Speedy Haulers'),
      "Expected Speedy Haulers ranked last, got: #{result.data.last[0..50]}"
  end
end

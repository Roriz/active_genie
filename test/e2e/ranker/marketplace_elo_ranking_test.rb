# frozen_string_literal: true

require_relative '../test_helper'

class MarketplaceEloRankingTest < Minitest::Test
  def setup
    @payload = load_fixture('marketplace/product_search_queries.json')
    @players = @payload[:products].map { |p| JSON.generate(p) }
    @criteria = "Query: '#{@payload[:search_query]}'. Rank products from best match to worst match based on active noise cancellation, calls quality, and wireless features."
  end

  def test_ranks_marketplace_products_via_elo
    result = ActiveGenie::Ranker.by_elo(@players, @criteria)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Array, result.data
    assert_equal @players.size, result.data.size

    # AcousticPro ANC 500 has ANC, wireless, long battery, dual mic — best match for remote SWE
    assert result.data.first.include?('AcousticPro ANC 500'),
      "Expected AcousticPro ANC 500 ranked first, got: #{result.data.first[0..50]}"
    # BasicBuds Lite has passive isolation, short battery — worst match for noise-canceling needs
    assert result.data.last.include?('BasicBuds Lite'),
      "Expected BasicBuds Lite ranked last, got: #{result.data.last[0..50]}"
  end
end

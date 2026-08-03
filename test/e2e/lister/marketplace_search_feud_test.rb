# frozen_string_literal: true

require_relative '../test_helper'

class MarketplaceSearchFeudTest < Minitest::Test
  def setup
    @theme = 'Most common search filters used by online shoppers when purchasing electronics on an e-commerce marketplace'
  end

  def test_lists_marketplace_search_intent_via_feud
    result = ActiveGenie::Lister.with_feud(@theme)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Array, result.data
    refute_empty result.data

    # "Price" is overwhelmingly the #1 search filter for electronics e-commerce
    assert result.data.first.to_s.downcase.include?('price'),
      "Expected top feud answer to be price-related, got: #{result.data.first}"
    # The least common filter should not be price — model must differentiate popularity
    refute result.data.last.to_s.downcase.include?('price'),
      "Expected last feud answer to NOT be price-related, got: #{result.data.last}"

    refute_nil result.reasoning
  end
end

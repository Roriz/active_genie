# frozen_string_literal: true

require_relative '../test_helper'

class MarketplaceVendorFightTest < Minitest::Test
  def setup
    @payload = load_fixture('marketplace/vendor_quotes.json')
    @vendor_a = JSON.generate(@payload[:vendor_a])
    @vendor_b = JSON.generate(@payload[:vendor_b])
    @criteria = 'Compare timeline, SLA uptime, and total cost to determine the best enterprise cloud migration partner.'
  end

  def test_compares_competing_vendor_quotes_via_fight
    result = ActiveGenie::Comparator.by_fight(@vendor_a, @vendor_b, @criteria)

    assert_kind_of ActiveGenie::Result, result
    # CloudSecure (faster, better SLA) should win for enterprise cloud migration
    assert_equal @vendor_a, result.data,
      'Expected CloudSecure (vendor_a) to win the fight for enterprise cloud migration partner'
  end
end

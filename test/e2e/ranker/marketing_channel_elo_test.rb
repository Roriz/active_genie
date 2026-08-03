# frozen_string_literal: true

require_relative '../test_helper'

class MarketingChannelEloTest < Minitest::Test
  def test_rank_marketing_channels
    channels = [
      JSON.generate(channel: "SEO", focus: "Organic Search"),
      JSON.generate(channel: "PPC", focus: "Paid Search"),
      JSON.generate(channel: "Social Media", focus: "Brand Awareness"),
      JSON.generate(channel: "Email", focus: "Direct Outreach")
    ]

    result = ActiveGenie::Ranker.by_elo(channels, "B2B SaaS lead generation")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    
    # WHY: Ranking is subjective for B2B SaaS, but it should output all 4 channels correctly.
    assert_equal 4, ranked.length, "Expected all 4 channels to be ranked, got: #{ranked.length}"
    assert_empty channels - ranked, "Result should contain all original channels"
  end
end

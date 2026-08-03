# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class MarketingCampaignFightTest < Minitest::Test
  def test_fight_marketing_campaign
    player_a = "Campaign A: High-budget traditional TV commercials during prime time"
    player_b = "Campaign B: Low-budget, highly targeted viral social media influencer push"
    criteria = "Which is the better marketing campaign strategy?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Ambiguous effectiveness depending on target audience. Assert valid choice.
    assert_includes [player_a, player_b], result.data, "Expected Campaign A or B. Got: #{result.data}"

  end
end

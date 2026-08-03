# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class EnterpriseCollabFightTest < Minitest::Test
  def test_fight_enterprise_collab
    player_a = "Zoom: Market leader in video quality and reliability, easy to join"
    player_b = "Microsoft Teams: Deeply integrated with Office 365, includes chat and file sharing"
    criteria = "Which tool is better for enterprise remote collaboration?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Subjective choice depending on enterprise needs (video focus vs suite integration). Assert valid choice.
    assert_includes [player_a, player_b], result.data, "Expected Zoom or Teams. Got: #{result.data}"

  end
end

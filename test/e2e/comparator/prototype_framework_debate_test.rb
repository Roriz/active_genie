# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class PrototypeFrameworkDebateTest < Minitest::Test
  def test_debate_prototype_framework
    player_a = "React: Huge ecosystem, large bundle size, complex state management"
    player_b = "Svelte: Simpler paradigm, less boilerplate, extremely fast development for small apps"
    criteria = "Which framework is better to build a prototype MVP in 2 weeks?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Svelte's speed of development and simplicity makes it better for a 2-week MVP
    assert_equal player_b, result.data, "Expected Svelte to win for a fast 2-week MVP. Got: #{result.data}"

  end
end

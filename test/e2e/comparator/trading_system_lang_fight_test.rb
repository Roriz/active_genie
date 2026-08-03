# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class TradingSystemLangFightTest < Minitest::Test
  def test_fight_trading_system_lang
    player_a = "Python: Interpreted, garbage collected, great data science ecosystem"
    player_b = "Rust: Compiled, zero-cost abstractions, memory safe, extremely low latency"
    criteria = "Which language is better for a high-performance, low-latency financial trading system?"

    result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: Rust's low latency and high performance make it the clear winner for HFT
    assert_equal player_b, result.data, "Expected Rust to win for low latency trading. Got: #{result.data}"

  end
end

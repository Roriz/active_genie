# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Comparator
    class FightTest < Minitest::Test
      def test_goku_vs_vegeta
        result = ActiveGenie::Comparator.fight(
          'Goku',
          'Vegeta',
          'who is stronger? Without any restrictions'
        )

        assert_equal 'player_a', result.winner
      end
    end
  end
end

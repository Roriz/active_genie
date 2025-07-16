# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Factory
    class FeudTest < Minitest::Test
      def test_feud_most_likely_to_be_affected_by_climate_change
        result = ActiveGenie::Factory.feud(
          'Industries that are most likely to be affected by climate change'
        )

        assert_equal 5, result.length
        assert_includes result, 'Agriculture', "Agriculture should be in the list, full result: #{result}"
        assert_includes result, 'Energy', "Energy should be in the list, full result: #{result}"
        assert_includes result, 'Tourism', "Tourism should be in the list, full result: #{result}"
      end

      def test_feud_with_more_items
        result = ActiveGenie::Factory.feud(
          'Industries that are most likely to be affected by climate change',
          config: { factory: { number_of_items: 10 } }
        )

        assert_equal 10, result.length
      end
    end
  end
end

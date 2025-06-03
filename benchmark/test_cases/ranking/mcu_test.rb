# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Ranking
    class McuTest < Minitest::Test
      def test_rank_strongest_character_from_mcu
        characters = JSON.parse(File.read('benchmark/test_cases/assets/marvel_characters.json'), symbolize_names: true)

        fight_criteria = <<~CRITERIA
          Determine the strongest character in the Marvel Cinematic Universe (MCU) based on their ability to consistently win in a fight against an opponent, considering all possible variables such as weapons, strategies, and scenarios.

          In your evaluation:
          - Consider all known abilities, strengths, and weaknesses of each character within the MCU canon (including films, official tie-in media).
          - Account for the versatility and adaptability of each character's strategies and weapons.
          - Determine which character can achieve a consistent victory across the majority of plausible scenarios.

          # Steps
          1. **Evaluate Abilities**: Analyze the powers, abilities, and any relevant enhancements each character possesses.
          2. **Assess Scenarios**: Consider various hypothetical combat scenarios, including differences in terrain, preparation, and available resources.
          3. **Consistency of Victory**: For each character, evaluate their ability to win across multiple scenarios and identify how often they could consistently triumph over others.
          4. **Conclude**: Identify the character who demonstrates the highest likelihood of consistent victories against others in most scenarios.

          # A Perfectly Balanced Battle Arena
          Dimensions: 200m x 200m circular arena
          Ceiling height: 100m dome
          Flat terrain (no cover)

          # Rules
          None, the players are free to use any means necessary to win the fight.
        CRITERIA
        result = ActiveGenie::Ranking.call(characters, fight_criteria)

        thanos_index = result.index { |r| r[:content].include? 'Thanos' }
        tony_stark_index = result.index { |r| r[:content].include? 'Tony Stark' }
        happy_hogan_index = result.index { |r| r[:content].include? 'Happy Hogan' }

        assert_equal result.length, 51
        assert thanos_index <= 3, "Thanos should be on top3 but it was #{thanos_index}"
        assert tony_stark_index <= 20, "Tony Stark should be on top20 but it was #{tony_stark_index}"
        assert happy_hogan_index >= 45, "Happy Hogan should be on bottom5 but it was #{happy_hogan_index}"
      end
    end
  end
end

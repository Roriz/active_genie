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

        CRITERIA
        result = ActiveGenie::Ranking.call(characters, fight_criteria)

        puts result.map { |r|
          [r.rank, r.content[0..30], r.score, r.elo, r.ffa_win_count, r.ffa_lose_count, r.ffa_draw_count, r.eliminated]
        }.to_json
        thanos = result.find { |r| r[:content].include? 'Thanos' }
        captain_m = result.find { |r| r[:content].include? 'Captain Marvel' }
        tony_stark = result.find { |r| r[:content].include? 'Tony Stark' }

        assert_equal result.length, 51
        assert thanos[:rank] <= 3, "Thanos should be on top but it was #{thanos[:rank]}"
        assert captain_m[:rank] <= 3, "Captain Marvel should be on top but it was #{captain_m[:rank]}"
        assert tony_stark[:rank] <= 10, "Tony Stark should be on top but it was #{tony_stark[:rank]}"
      end
    end
  end
end

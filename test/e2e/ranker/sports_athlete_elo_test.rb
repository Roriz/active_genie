# frozen_string_literal: true

require_relative '../test_helper'

class SportsAthleteEloTest < Minitest::Test
  def test_rank_athletes
    athletes = [
      JSON.generate(type: "Olympic Gold Medalist Sprinter", pace: "World class"),
      JSON.generate(type: "Weekend Jogger", pace: "Casual"),
      JSON.generate(type: "Couch Potato", pace: "None")
    ]

    result = ActiveGenie::Ranker.by_elo(athletes, "winning a 100m race")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    assert_equal 3, ranked.length

    olympian = athletes[0]
    potato = athletes[2]

    # WHY: An Olympic sprinter will obviously win a 100m race over a couch potato.
    assert_equal olympian, ranked.first, "Expected Olympian to be ranked first, got: #{ranked.first}"
    assert_equal potato, ranked.last, "Expected Couch Potato to be ranked last, got: #{ranked.last}"
  end
end

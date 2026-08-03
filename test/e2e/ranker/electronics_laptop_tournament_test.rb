# frozen_string_literal: true

require_relative '../test_helper'

class ElectronicsLaptopTournamentTest < Minitest::Test
  def test_rank_laptops
    laptops = [
      JSON.generate(type: "Gaming", price: 3000, specs: "Core i9, 32GB RAM, RTX 4080"),
      JSON.generate(type: "Business", price: 1500, specs: "Core i7, 16GB RAM, Integrated Graphics"),
      JSON.generate(type: "Chromebook", price: 200, specs: "Celeron, 4GB RAM, ChromeOS")
    ]

    result = ActiveGenie::Ranker.by_tournament(laptops, "laptop for serious software development")

    assert_kind_of ActiveGenie::Result, result

    ranked_laptops = result.data
    assert_equal 3, ranked_laptops.length

    chromebook = laptops[2]

    # WHY: A Chromebook with 4GB RAM is unsuitable for serious software development compared to the others.
    assert_equal chromebook, ranked_laptops.last, "Expected Chromebook to be ranked last, got: #{ranked_laptops.last}"
  end
end

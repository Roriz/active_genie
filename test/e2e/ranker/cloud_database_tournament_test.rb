# frozen_string_literal: true

require_relative '../test_helper'

class CloudDatabaseTournamentTest < Minitest::Test
  def test_rank_similar_cloud_databases
    dbs = [
      JSON.generate(name: "CloudDB A", features: "NoSQL, scalable, 99.99% uptime, $10/mo"),
      JSON.generate(name: "CloudDB B", features: "NoSQL, scalable, 99.95% uptime, $9/mo"),
      JSON.generate(name: "CloudDB C", features: "NoSQL, scalable, 99.999% uptime, $11/mo")
    ]

    result = ActiveGenie::Ranker.by_tournament(dbs, "cost-effective database for small startup")

    assert_kind_of ActiveGenie::Result, result

    ranked_dbs = result.data
    
    # WHY: Ranking is ambiguous because trade-offs between cost and uptime are marginal.
    # Just asserting that it returns all three items.
    assert_equal 3, ranked_dbs.length, "Expected all 3 databases to be ranked, got: #{ranked_dbs.length}"
    assert_empty dbs - ranked_dbs, "Result should contain all the original databases"
  end
end

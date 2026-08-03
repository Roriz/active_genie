# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class FinancialDbDebateTest < Minitest::Test
  def test_debate_financial_db
    player_a = "PostgreSQL: Relational, strict ACID guarantees, strong schema"
    player_b = "MongoDB: NoSQL, document-oriented, flexible schema"
    criteria = "Which database is better for real-time analytics on structured financial data requiring strict consistency?"

    result = ActiveGenie::Comparator.by_debate(player_a, player_b, criteria)

    # All tests must assert result type
    assert_kind_of ActiveGenie::Result, result

    # WHY: PostgreSQL is the obvious choice for structured financial data with strict ACID requirements
    assert_equal player_a, result.data, "Expected PostgreSQL to win for financial data. Got: #{result.data}"

  end
end

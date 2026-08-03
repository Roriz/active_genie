# frozen_string_literal: true

require_relative '../test_helper'

class FinancePortfolioTournamentTest < Minitest::Test
  def test_rank_investment_portfolios
    portfolios = [
      JSON.generate(type: "Aggressive Growth", allocation: "100% Stocks"),
      JSON.generate(type: "Conservative Bonds", allocation: "80% Bonds, 20% Stocks"),
      JSON.generate(type: "Balanced", allocation: "60% Stocks, 40% Bonds"),
      JSON.generate(type: "Crypto-heavy", allocation: "100% Cryptocurrency")
    ]

    result = ActiveGenie::Ranker.by_tournament(portfolios, "retirement savings for 55-year-old nearing retirement")

    assert_kind_of ActiveGenie::Result, result

    ranked_portfolios = result.data
    assert_equal 4, ranked_portfolios.length

    crypto = portfolios[3]
    
    # WHY: 55-year-olds shouldn't risk their entire retirement in crypto. Bonds/balanced are safer.
    assert_equal crypto, ranked_portfolios.last, "Expected Crypto-heavy to be ranked last due to high risk, got: #{ranked_portfolios.last}"
  end
end

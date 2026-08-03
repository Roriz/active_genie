# frozen_string_literal: true

require_relative '../test_helper'

class SaasTicketScoringRankTest < Minitest::Test
  def setup
    @tickets = [
      { id: 'TCK-101', summary: 'Billing page error 500 during credit card submission', impact: 'high' },
      { id: 'TCK-102', summary: 'Typo on footer documentation link', impact: 'low' },
      { id: 'TCK-103', summary: 'Export CSV button takes 10 seconds to download', impact: 'medium' }
    ].map { |t| JSON.generate(t) }
    @criteria = 'Evaluate customer impact and urgency for engineering sprint backlog prioritization.'
  end

  def test_ranks_saas_tickets_via_scoring
    result = ActiveGenie::Ranker.by_scoring(@tickets, @criteria)

    assert_kind_of Array, result
    refute_empty result
  end
end

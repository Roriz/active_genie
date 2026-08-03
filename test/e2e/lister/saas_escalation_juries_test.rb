# frozen_string_literal: true

require_relative '../test_helper'

class SaasEscalationJuriesTest < Minitest::Test
  def setup
    @payload = load_fixture('saas/support_escalation.json')
    @text = JSON.generate(@payload)
    @criteria = 'Identify expert technical roles needed to conduct incident post-mortem and evaluate system recovery actions.'
  end

  def test_recommends_saas_incident_juries
    result = ActiveGenie::Lister.with_juries(@text, @criteria)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    assert_kind_of Array, result.data
    refute_empty result.data

    # DB connection pool exhaustion — top jury should relate to database expertise
    db_keywords = %w[database dba data backend]
    assert db_keywords.any? { |kw| result.data.first.to_s.downcase.include?(kw) },
      "Expected top jury to be database-related for DB pool incident, got: #{result.data.first}"
    # Incident recovery requires infrastructure/SRE expertise somewhere in the list
    infra_keywords = %w[sre reliability infrastructure devops operations platform]
    assert result.data.any? { |jury| infra_keywords.any? { |kw| jury.to_s.downcase.include?(kw) } },
      "Expected at least one SRE/infrastructure jury for incident post-mortem, got: #{result.data}"

    refute_nil result.reasoning
  end
end

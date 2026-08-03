# frozen_string_literal: true

require_relative '../test_helper'

class DevopsIncidentReportExplanationTest < Minitest::Test
  def test_extract_root_cause_and_affected_systems
    text = "At 14:00 UTC, the authentication service started failing with 500s. Investigation revealed that a botched database migration locked the users table, causing cascading timeouts in the API gateway and the frontend dashboard."
    schema = {
      root_cause: { type: 'string', description: 'The underlying cause of the incident' },
      affected_systems: { type: 'array', items: { type: 'string' }, description: 'Systems that experienced impact' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM needs to distinguish between the symptom (500s) and root cause (migration/locked table)
    assert_match(/migration|database|locked table/i, data[:root_cause], "Expected root cause to relate to DB migration, got #{data[:root_cause]}")
    affected = data[:affected_systems].map(&:to_s).join(' ').downcase
    assert_match(/authentication|auth|api|gateway|frontend|dashboard/i, affected, "Expected affected systems to include auth/api/frontend, got #{data[:affected_systems]}")
    refute_nil result.reasoning
  end
end

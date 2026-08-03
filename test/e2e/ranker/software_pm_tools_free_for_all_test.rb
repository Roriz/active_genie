# frozen_string_literal: true

require_relative '../test_helper'

class SoftwarePmToolsFreeForAllTest < Minitest::Test
  def test_rank_pm_tools
    tools = [
      JSON.generate(name: "Tool A", features: "Kanban, Gantt, time tracking"),
      JSON.generate(name: "Tool B", features: "Kanban, Gantt, reporting"),
      JSON.generate(name: "Tool C", features: "Kanban, Gantt, dashboards")
    ]

    result = ActiveGenie::Ranker.by_free_for_all(tools, "best project management tool for a small team")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    
    # WHY: All 3 tools have overlapping features and ambiguous value for a general small team.
    assert_equal 3, ranked.length, "Expected all 3 tools to be ranked, got: #{ranked.length}"
    assert_empty tools - ranked, "Result should contain all the original tools"
  end
end

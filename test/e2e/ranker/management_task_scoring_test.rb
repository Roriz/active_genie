# frozen_string_literal: true

require_relative '../test_helper'

class ManagementTaskScoringTest < Minitest::Test
  def test_score_equal_tasks
    tasks = [
      JSON.generate(task: "Update documentation for V1", priority: "Normal"),
      JSON.generate(task: "Update documentation for V2", priority: "Normal"),
      JSON.generate(task: "Update documentation for V3", priority: "Normal")
    ]

    result = ActiveGenie::Ranker.by_scoring(tasks, "team weekly planning")

    # WHY: by_scoring returns a raw Array, not a Result object
    assert_kind_of Array, result, "Expected result to be an Array, got: #{result.class}"
    refute_empty result, "Expected non-empty array of scores"
    assert_equal 3, result.length, "Expected 3 tasks to be scored"
  end
end

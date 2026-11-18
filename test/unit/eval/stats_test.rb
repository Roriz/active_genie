# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../eval/lib/genie_eval'

class GenieEvalStatsTest < Minitest::Test
  Stats = GenieEval::Stats

  def test_exact_mcnemar
    assert_in_delta 1.0, Stats.mcnemar_p(0, 0)
    assert_in_delta 0.0625, Stats.mcnemar_p(0, 5) # 2 * 0.5^5
    assert_in_delta 1.0, Stats.mcnemar_p(3, 3)
    assert_in_delta 0.021, Stats.mcnemar_p(1, 9), 0.001
  end

  def test_weighted_mean_renormalizes_over_present_strata
    strata = { 'a' => [1, 1], 'b' => [0, 0], 'c' => [] }

    assert_in_delta 0.5, Stats.weighted_mean(strata, { 'a' => 1, 'b' => 1, 'c' => 5 })
    assert_in_delta 0.75, Stats.weighted_mean(strata, { 'a' => 3, 'b' => 1 })
  end

  def test_bootstrap_ci_is_seeded_and_brackets_the_mean
    values = [1, 0, 1, 1, 0, 1, 1, 1, 0, 1]
    ci = Stats.bootstrap_ci(values, resamples: 2000)

    assert_equal ci, Stats.bootstrap_ci(values, resamples: 2000)
    assert_operator ci[0], :<, 0.7
    assert_operator ci[1], :>, 0.7
  end

  def test_cluster_bootstrap_is_wider_for_correlated_values
    clusters = [[1, 1, 1, 1], [0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0]]
    clustered = Stats.bootstrap_ci(clusters:, resamples: 2000)
    flat = Stats.bootstrap_ci(clusters.flatten, resamples: 2000)

    assert_operator clustered[1] - clustered[0], :>, flat[1] - flat[0]
  end

  def test_wilson_and_mde
    lo, hi = Stats.wilson(9, 10)

    assert_in_delta 0.596, lo, 0.01
    assert_in_delta 0.982, hi, 0.01
    assert_in_delta 0.219, Stats.mde(0.9, 30), 0.001
    assert_operator Stats.mde(1.0, 30), :>, 0
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Statistics for small paired samples. All resampling is seeded, so reports are reproducible.
    module Stats
      module_function

      def mean(values)
        values.empty? ? nil : values.sum.to_f / values.size
      end

      # Nearest-rank quantile of an already sorted array.
      def quantile(sorted, q)
        return nil if sorted.empty?

        sorted[[(q * sorted.size).ceil - 1, 0].max]
      end

      # Percentile bootstrap CI of the mean. Pass `clusters` (one array of values per case) to
      # resample whole cases, so correlated values (an extractor case's fields) move together.
      def bootstrap_ci(values = nil, clusters: nil, resamples: 10_000, level: 0.95, seed: 0)
        clusters ||= values.map { |v| [v] }
        return nil if clusters.empty?

        rng = Random.new(seed)
        means = Array.new(resamples) do
          picked = Array.new(clusters.size) { clusters[rng.rand(clusters.size)] }.flatten
          mean(picked)
        end.sort
        tail = (1 - level) / 2
        [quantile(means, tail), quantile(means, 1 - tail)]
      end

      # Weighted mean of per-stratum means, with weights renormalized over strata present.
      def weighted_mean(strata, weights)
        present = strata.reject { |_k, v| v.empty? }
        total = present.keys.sum { |k| weights.fetch(k, 1) }.to_f
        return nil if total.zero?

        present.sum { |k, v| weights.fetch(k, 1) * mean(v) } / total
      end

      # Stratified bootstrap CI of `weighted_mean`: resamples within each stratum.
      def stratified_ci(strata, weights, resamples: 2000, level: 0.95, seed: 0)
        present = strata.reject { |_k, v| v.empty? }
        return nil if present.empty?

        rng = Random.new(seed)
        draws = Array.new(resamples) do
          resampled = present.transform_values { |v| Array.new(v.size) { v[rng.rand(v.size)] } }
          weighted_mean(resampled, weights)
        end.sort
        tail = (1 - level) / 2
        [quantile(draws, tail), quantile(draws, 1 - tail)]
      end

      # Exact two-sided McNemar test on the discordant counts: b = broke, c = fixed.
      def mcnemar_p(broke, fixed)
        n = broke + fixed
        return 1.0 if n.zero?

        tail = (0..[broke, fixed].min).sum { |k| binomial(n, k) } / (2.0**n)
        [1.0, 2 * tail].min
      end

      def binomial(n, k)
        (1..k).reduce(1) { |acc, i| acc * (n - k + i) / i }
      end

      # Wilson score interval for k successes out of n.
      def wilson(k, n, z: 1.96)
        return nil if n.zero?

        p = k.to_f / n
        center = (p + ((z**2) / (2 * n))) / (1 + ((z**2) / n))
        half = z * Math.sqrt((p * (1 - p) / n) + ((z**2) / (4 * (n**2)))) / (1 + ((z**2) / n))
        [center - half, center + half]
      end

      # Rough minimum detectable effect for a paired comparison at accuracy p over n cases.
      def mde(p, n)
        return nil if n.zero?

        p = p.clamp(0.05, 0.95) # at 0% or 100% the formula says 0, which is never true
        4 * Math.sqrt(p * (1 - p) / n)
      end
    end
  end
end

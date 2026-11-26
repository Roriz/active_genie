# frozen_string_literal: true

module ActiveGenie
  module Eval
    # The text report of one eval: pass rate per set and overall with a CI, the paired comparison with
    # the baseline (delta, exact McNemar p, MDE), field outcomes or rubric scores, the noise floor, what
    # broke or got fixed and, for quick runs, a GO / LOOK / STOP verdict.
    class Scoreboard
      def initialize(system:, items:, mode:)
        @system = system
        @definition = system.definition
        @items = items
        @mode = mode
        loaded = Results.load(@definition, system.run_root, items)
        @missing = loaded.missing # not run yet for this code: left out of every rate, never a failure
        @current = Results.new(loaded.rows - @missing)
        load_baseline
      end

      def report
        lines = header + set_table + overall + field_outcomes + scores + noise_floor + problems + flips
        lines += ["VERDICT: #{verdict}"] if @mode.to_s == 'quick'
        lines.join("\n")
      end

      # STOP: a canary (a case the baseline passed in every replicate) broke. LOOK: something else broke,
      # errored or is missing, or no case could be compared with the baseline. GO: nothing broke.
      def verdict
        return 'NO BASELINE' unless @baseline
        return 'STOP' if broke.any? { |row| canary?(row) }
        return 'LOOK' if broke.any? || @current.errors.any? || @missing.any? || paired.empty?

        'GO'
      end

      private

      def load_baseline
        replicates = @system.baseline_replicates
        return if replicates.empty?

        base = replicates.map { |r| Results.load(@definition, @system.baseline_dir, @items, replicate: r) }
        # A case the baseline never ran (new, or its input changed since) is unpaired, not a failure.
        @baseline = Results.new(base.first.rows - base.first.missing)
        always = ->(key) { base.all? { |b| b.by_key[key].then { |row| row.record && row.pass? } } }
        @canaries = @items.map(&:key).select(&always).to_set
      end

      def canary?(row)
        @canaries&.include?(row.key)
      end

      def pct(value)
        value.nil? ? '   -  ' : format('%5.1f%%', value * 100)
      end

      def interval(range)
        range ? "[#{pct(range[0]).strip}, #{pct(range[1]).strip}]" : ''
      end

      def header
        base = @baseline ? baseline_description : 'none yet (run eval:full on main, then eval:save)'
        ["ActiveGenie eval - #{@mode} - #{@system.describe}", "baseline: #{base}", '']
      end

      def baseline_description
        file = File.join(@system.baseline_dir, 'BASE.json')
        meta = File.exist?(file) ? JSON.parse(File.read(file)) : {}
        "#{meta['branch']} #{meta['sha'].to_s[0, 8]} (code #{meta['code_hash'].to_s[0, 8]}, saved #{meta['saved_at']})"
      end

      def set_table
        rows = @current.rows.group_by { |r| r.item.set }.map do |set, set_rows|
          passed = set_rows.count(&:pass?)
          format('%-28s %4d %6d %8s', set, set_rows.size, passed, pct(passed.to_f / set_rows.size))
        end
        ['set                            n   pass     rate', *rows, '']
      end

      def overall
        n = @current.rows.size
        return [] if n.zero?

        passed = @current.rows.count(&:pass?)
        rate = passed.to_f / n
        mde = [Stats.mde(rate, n), 1.0].min
        lines = ["pass rate: #{pct(rate).strip} #{interval(Stats.wilson(passed, n))} (#{passed}/#{n})",
                 "smallest change this many cases can reliably detect (MDE): ~#{pct(mde).strip}"]
        lines << delta_line if @baseline
        lines << ''
      end

      def paired
        @paired ||= @current.rows.filter_map { |row| (base = @baseline.by_key[row.key]) && [row, base] }
      end

      def delta_line
        deltas = paired.map { |cur, base| (cur.pass? ? 1 : 0) - (base.pass? ? 1 : 0) }
        ci = Stats.bootstrap_ci(deltas)
        ci_text = ci ? format('[%+.1f, %+.1f]', ci[0] * 100, ci[1] * 100) : ''
        format('delta vs baseline: %+.1f pp %s on %d paired cases, McNemar p=%.3f (%d broke, %d fixed)',
               (Stats.mean(deltas) || 0) * 100, ci_text, paired.size, Stats.mcnemar_p(broke.size, fixed.size),
               broke.size, fixed.size)
      end

      def broke
        @broke ||= @baseline ? paired.select { |cur, base| base.pass? && !cur.pass? }.map(&:first) : []
      end

      def fixed
        @fixed ||= @baseline ? paired.select { |cur, base| !base.pass? && cur.pass? }.map(&:first) : []
      end

      def field_outcomes
        rows = @current.rows.select { |r| r.grade.detail['fields'] }
        return [] if rows.empty?

        counts = rows.flat_map { |r| r.grade.detail['fields'].values }.tally
        clusters = rows.map { |r| r.grade.detail['fields'].values.map { |o| Graders::Fields::RIGHT.include?(o) ? 1 : 0 } }
        ["fields: #{pct(Stats.mean(clusters.flatten)).strip} right #{interval(Stats.bootstrap_ci(clusters:))} " \
         '(CI resamples whole cases)', "  #{counts.sort.map { |k, v| "#{k} #{v}" }.join(', ')}", '']
      end

      # Mean score for band and rubric graders.
      def scores
        values = @current.rows.filter_map { |r| r.grade.detail['score'] }
        return [] if values.empty?

        [format('mean score: %.1f over %d cases', Stats.mean(values), values.size), '']
      end

      # Share of cases whose pass/fail differs between replicates of the same code.
      def noise_floor
        replicates = @system.replicates
        return [] if replicates.size < 2

        runs = replicates.map { |r| Results.load(@definition, @system.run_root, @items, replicate: r).by_key }
        # Only replicates that have an output count: a case missing from one is not a flip.
        compared = @items.map { |item| runs.map { |run| run[item.key] }.select { |row| row&.record }.map(&:pass?) }
                         .select { |outcomes| outcomes.size > 1 }
        return [] if compared.empty?

        flipping = compared.count { |outcomes| outcomes.uniq.size > 1 }
        ["noise floor: #{pct(flipping.to_f / compared.size).strip} of #{compared.size} cases flip across " \
         "#{replicates.size} identical runs", '']
      end

      def problems
        lines = @current.errors.map { |r| "ERROR   #{r.key}: #{r.record['error'].lines.first&.strip}" }
        if @missing.any?
          lines << "MISSING #{@missing.size} of #{@items.size} cases have no output for this code yet " \
                   '(left out of the rates; run with YES=1)'
        end
        unjudged = @current.rows.count { |r| r.grade.unjudged? }
        lines << "UNJUDGED #{unjudged} case(s) wait for the judge and count as failures (run with YES=1)" if unjudged.positive?
        lines.empty? ? [] : [*lines, '']
      end

      # With a baseline: what broke or got fixed. Without one: every failing case.
      def flips
        lines = if @baseline
                  broke.map { |r| "BROKE   #{r.key}#{' (canary)' if canary?(r)} #{brief(r)}" } +
                    fixed.map { |r| "FIXED   #{r.key}" }
                else
                  @current.rows.reject { |r| r.pass? || r.record['error'] }.map { |r| "FAIL    #{r.key} #{brief(r)}" }
                end
        lines.empty? ? [] : [*lines, '']
      end

      def brief(row)
        JSON.generate(row.grade.detail)[0, 160]
      end
    end
  end
end

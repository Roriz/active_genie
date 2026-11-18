# frozen_string_literal: true

module GenieEval
  # Turns graded results into the text report: per-cell rates, the weighted number with a CI,
  # the paired comparison with the baseline (McNemar, delta CI, MDE), module diagnostics,
  # the noise floor, the broke/fixed list and, for quick runs, a GO / LOOK / STOP verdict.
  class Scoreboard
    def initialize(system:, items:, mode:)
      @system = system
      @items = items
      @mode = mode
      loaded = Results.load(system.run_root, items)
      @missing = loaded.missing # not run yet for this lib/: left out of every rate, never a failure
      @current = Results.new(loaded.rows - @missing)
      @baseline = Results.load(system.baseline_dir, items) if Dir.exist?(File.join(system.baseline_dir, 'r1'))
      @weights = Store.cells.to_h { |c| [c['id'], c.fetch('weight', 1)] }
    end

    def report
      lines = header + cell_table + overall + extractor_outcomes + comparator_consistency +
              noise_floor + problems + flips
      lines += verdict_lines if @mode.to_s == 'quick'
      lines.join("\n")
    end

    def verdict
      return 'NO BASELINE' unless @baseline
      return 'STOP' if broke.any? { |row| row.item.role == 'canary' }
      return 'LOOK' if broke.any? || @current.errors.any? || @missing.any?

      'GO'
    end

    private

    def pct(value)
      value.nil? ? '   -  ' : format('%5.1f%%', value * 100)
    end

    def interval(range)
      range ? "[#{pct(range[0]).strip}, #{pct(range[1]).strip}]" : ''
    end

    def header
      base = @baseline ? baseline_description : 'none (run `rake eval:full` on main, then `rake eval:save`)'
      ["ActiveGenie eval - #{@mode} - #{@system.describe}", "baseline: #{base}", '']
    end

    def baseline_description
      meta_file = File.join(@system.baseline_dir, 'BASE.json')
      meta = File.exist?(meta_file) ? JSON.parse(File.read(meta_file)) : {}
      "#{meta['branch']} #{meta['sha'].to_s[0, 8]} (lib #{meta['lib_hash'].to_s[0, 8]}, saved #{meta['saved_at']})"
    end

    def cell_table
      head = 'cell                            n   pass     rate'
      head += '     base   delta broke fixed       p' if @baseline
      rows = @current.by_cell.map { |cell, rows_| cell_line(cell, rows_) }
      [head, *rows, '']
    end

    def cell_line(cell, rows)
      passed = rows.count(&:pass?)
      line = format('%-28s %4d %6d %8s', cell, rows.size, passed, pct(passed.to_f / rows.size))
      return line unless @baseline

      pairs = paired(rows)
      b = pairs.count { |cur, base| base.pass? && !cur.pass? }
      f = pairs.count { |cur, base| !base.pass? && cur.pass? }
      base_rate = pairs.count { |_c, base| base.pass? }.to_f / pairs.size
      cur_rate = pairs.count { |cur, _b| cur.pass? }.to_f / pairs.size
      line + format(' %8s %+6.1f %5d %5d %7.3f', pct(base_rate), (cur_rate - base_rate) * 100, b, f,
                    Stats.mcnemar_p(b, f))
    end

    def paired(rows)
      rows.filter_map { |row| (base = @baseline.by_key[row.key]) && [row, base] }
    end

    def overall
      strata = @current.strata
      rate = Stats.weighted_mean(strata, @weights)
      n = strata.values.sum(&:size)
      return [] if n.zero?

      lines = ["weighted pass rate (equal cell weights): #{pct(rate)} #{interval(Stats.stratified_ci(strata, @weights))}"]
      lines << "smallest change this sample can reliably detect (MDE): ~#{pct(Stats.mde(rate || 0.5, n)).strip} overall"
      lines.concat(delta_lines) if @baseline
      lines << ''
    end

    def delta_lines
      pairs = paired(@current.rows)
      deltas = pairs.group_by { |cur, _b| cur.item.cell }
                    .transform_values { |ps| ps.map { |cur, base| (cur.pass? ? 1 : 0) - (base.pass? ? 1 : 0) } }
      delta = Stats.weighted_mean(deltas, @weights)
      ci = Stats.stratified_ci(deltas, @weights)
      p = Stats.mcnemar_p(broke.size, fixed.size)
      ci_text = ci ? format('[%+.1f, %+.1f]', ci[0] * 100, ci[1] * 100) : ''
      [format('delta vs baseline: %+.1f pp %s, McNemar p=%.3f (%d broke, %d fixed)',
              (delta || 0) * 100, ci_text, p, broke.size, fixed.size)]
    end

    def broke
      @broke ||= @baseline ? paired(@current.rows).select { |cur, base| base.pass? && !cur.pass? }.map(&:first) : []
    end

    def fixed
      @fixed ||= @baseline ? paired(@current.rows).select { |cur, base| !base.pass? && cur.pass? }.map(&:first) : []
    end

    def extractor_outcomes
      rows = @current.rows.select { |r| r.item.cell.start_with?('extractor.') && r.grade.detail['fields'] }
      return [] if rows.empty?

      counts = rows.flat_map { |r| r.grade.detail['fields'].values }.tally
      clusters = rows.map { |r| r.grade.detail['fields'].values.map { |o| Graders::Extractor::RIGHT.include?(o) ? 1 : 0 } }
      right = Stats.mean(clusters.flatten)
      ["extractor fields: #{pct(right).strip} right #{interval(Stats.bootstrap_ci(clusters:))} (CI resamples whole cases)",
       "  #{counts.sort.map { |k, v| "#{k} #{v}" }.join(', ')}", '']
    end

    def comparator_consistency
      rows = @current.rows.select { |r| r.item.cell.start_with?('comparator.') && r.grade.detail.key?('consistent') }
      return [] if rows.empty?

      by_cell = rows.group_by { |r| r.item.cell }.map do |cell, cell_rows|
        "#{cell} #{pct(cell_rows.count { |r| r.grade.detail['consistent'] }.to_f / cell_rows.size).strip}"
      end
      ["comparator order consistency (same winner in both orders): #{by_cell.join(', ')}", '']
    end

    # Share of cases whose pass/fail differs between replicates of the same system.
    def noise_floor
      replicates = @system.replicates
      return [] if replicates.size < 2

      runs = replicates.map { |r| Results.load(@system.run_root, @items, replicate: r).by_key }
      flipping = @items.count { |item| runs.map { |run| run[item.key]&.pass? }.uniq.size > 1 }
      ["noise floor: #{pct(flipping.to_f / @items.size).strip} of cases flip across #{replicates.size} identical runs", '']
    end

    def problems
      lines = @current.errors.map { |r| "ERROR   #{r.key}: #{r.record['error'].lines.first&.strip}" }
      if @missing.any?
        lines << "MISSING #{@missing.size} of #{@items.size} cases have no output for this lib/ yet " \
                 '(left out of the rates; run with YES=1)'
      end
      lines.empty? ? [] : [*lines, '']
    end

    # With a baseline: what broke or got fixed. Without one: every failing case.
    def flips
      lines = if @baseline
                broke.map { |r| "BROKE   #{r.key}#{" (#{r.item.role})" if r.item.role} #{brief(r)}" } +
                  fixed.map { |r| "FIXED   #{r.key}" }
              else
                @current.rows.reject { |r| r.pass? || r.record['error'] }.map { |r| "FAIL    #{r.key} #{brief(r)}" }
              end
      lines.empty? ? [] : [*lines, '']
    end

    def brief(row)
      detail = row.grade.detail.except('items')
      JSON.generate(detail)[0, 160]
    end

    def verdict_lines
      ["VERDICT: #{verdict}"]
    end
  end
end

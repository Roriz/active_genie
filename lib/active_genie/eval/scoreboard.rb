# frozen_string_literal: true

module ActiveGenie
  module Eval
    # The report of one eval run: pass rate per set and overall with a CI, the paired comparison with
    # the baseline (delta, exact McNemar p, MDE), the confusion matrices (baseline vs now, field
    # outcomes, each categorical field, score bands), the noise floor, what broke or got fixed and, for
    # quick runs, a GO / LOOK / STOP verdict. `report` is terminal text, `markdown` the same as markdown.
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

      def report = document.to_text
      def markdown = document.to_markdown

      # STOP: a canary (a case the baseline passed in every replicate) broke. LOOK: something else broke,
      # errored or is missing, or no case could be compared with the baseline. GO: nothing broke.
      def verdict
        return 'NO BASELINE' unless @baseline
        return 'STOP' if broke.any? { |row| canary?(row) }
        return 'LOOK' if broke.any? || @current.errors.any? || @missing.any? || paired.empty?

        'GO'
      end

      private

      def document
        @document ||= begin
          doc = header.concat(summary)
          doc.concat(Matrices.baseline(paired)) if @baseline
          [Matrices.field_outcomes(@current.rows), Matrices.categorical(@current.rows), Matrices.bands(@current.rows),
           noise_floor, problems, flips].each { |section| doc.concat(section) }
          doc.blank.line("VERDICT: #{verdict}") if @mode.to_s == 'quick'
          doc
        end
      end

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
        value.nil? ? '-' : format('%.1f%%', value * 100)
      end

      def interval(range)
        range ? "[#{pct(range[0])}, #{pct(range[1])}]" : ''
      end

      def header
        base = @baseline ? baseline_description : 'none yet (run eval:full on main, then eval:save)'
        Report.new.line("ActiveGenie eval - #{@mode} - #{@system.describe}").line("baseline: #{base}")
      end

      def baseline_description
        file = File.join(@system.baseline_dir, 'BASE.json')
        meta = File.exist?(file) ? JSON.parse(File.read(file)) : {}
        "#{meta['branch']} #{meta['sha'].to_s[0, 8]} (code #{meta['code_hash'].to_s[0, 8]}, saved #{meta['saved_at']})"
      end

      def summary
        report = Report.new.heading('Results')
        n = @current.rows.size
        return report.line('no case has an output for this code yet') if n.zero?

        sets = @current.rows.group_by { |r| r.item.set }.map do |set, rows|
          passed = rows.count(&:pass?)
          [set, rows.size, passed, pct(passed.to_f / rows.size)]
        end
        report.table(%w[set cases pass rate], sets).blank
        passed = @current.rows.count(&:pass?)
        rate = passed.to_f / n
        report.line("pass rate: #{pct(rate)} #{interval(Stats.wilson(passed, n))} (#{passed}/#{n})")
              .line("smallest change this many cases can reliably detect (MDE): ~#{pct([Stats.mde(rate, n), 1.0].min)}")
        report.line(delta_line) if @baseline
        report.concat(fields_right).concat(scores)
      end

      def paired
        @paired ||= if @baseline
                      @current.rows.filter_map { |row| (base = @baseline.by_key[row.key]) && [row, base] }
                    else
                      []
                    end
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
        @broke ||= paired.select { |cur, base| base.pass? && !cur.pass? }.map(&:first)
      end

      def fixed
        @fixed ||= paired.select { |cur, base| !base.pass? && cur.pass? }.map(&:first)
      end

      def fields_right
        outcomes = @current.rows.filter_map { |r| Matrices.fields(r) }
        return Report.new if outcomes.empty?

        clusters = outcomes.map { |fields| fields.values.map { |o| Graders::Fields::RIGHT.include?(o) ? 1 : 0 } }
        Report.new.line("fields: #{pct(Stats.mean(clusters.flatten))} right " \
                        "#{interval(Stats.bootstrap_ci(clusters:))} (CI resamples whole cases)")
      end

      # Mean score for band and rubric graders.
      def scores
        values = @current.rows.map { |r| r.grade.detail['score'] }.grep(Numeric)
        return Report.new if values.empty?

        Report.new.line(format('mean score: %.1f over %d cases', Stats.mean(values), values.size))
      end

      # Share of cases whose pass/fail differs between replicates of the same code.
      def noise_floor
        replicates = @system.replicates
        return Report.new if replicates.size < 2

        runs = replicates.map { |r| Results.load(@definition, @system.run_root, @items, replicate: r).by_key }
        # Only replicates that have an output count: a case missing from one is not a flip.
        compared = @items.map { |item| runs.map { |run| run[item.key] }.select { |row| row&.record }.map(&:pass?) }
                         .select { |outcomes| outcomes.size > 1 }
        return Report.new if compared.empty?

        flipping = compared.count { |outcomes| outcomes.uniq.size > 1 }
        Report.new.heading('Noise').line("noise floor: #{pct(flipping.to_f / compared.size)} of #{compared.size} " \
                                         "cases flip across #{replicates.size} identical runs")
      end

      def problems
        lines = @current.errors.map { |r| "ERROR   #{r.key}: #{r.record['error'].lines.first&.strip}" }
        if @missing.any?
          lines << "MISSING #{@missing.size} of #{@items.size} cases have no output for this code yet " \
                   '(left out of the rates; run them to fill in)'
        end
        unjudged = @current.rows.count { |r| r.grade.unjudged? }
        if unjudged.positive?
          lines << "UNJUDGED #{unjudged} case(s) wait for the judge and count as failures (a confirmed run judges them)"
        end
        section('Problems', lines)
      end

      # With a baseline: what broke or got fixed. Without one: every failing case.
      def flips
        if @baseline
          lines = broke.map { |r| "BROKE   #{r.key}#{' (canary)' if canary?(r)} #{brief(r)}" } +
                  fixed.map { |r| "FIXED   #{r.key}" }
          return section('Changes since the baseline', lines)
        end

        failing = @current.rows.reject { |r| r.pass? || r.record['error'] }
        section('Failures', failing.map { |r| "FAIL    #{r.key} #{brief(r)}" })
      end

      def section(title, lines)
        return Report.new if lines.empty?

        lines.each_with_object(Report.new.heading(title)) { |line, report| report.line(line) }
      end

      def brief(row)
        JSON.generate(row.grade.detail)[0, 160]
      end
    end
  end
end

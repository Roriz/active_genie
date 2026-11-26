# frozen_string_literal: true

module ActiveGenie
  module Eval
    # What an eval holds before it runs: how many cases are in each pool and state, how varied they
    # are (difficulty, tags, sets, what the gold asks for), and, given a plan, what a run would call,
    # cost and take.
    #
    #   ticket_router · openai/gpt-6.1-terra · code 830a8f71 · main 3012c2b0
    #
    #   Cases           dev  test  total
    #     run            12    30     42
    #   ...
    #   Plan: quick, 12 dev cases, 4 cached, 8 to call
    #     ~8 case runs · ~32000 tokens · ~$0.04 · ~1:02
    class Overview
      STATES = { 'run' => ->(row) { Store.runs?(row) },
                 'waiting for labels' => ->(row) { %w[draft queued].include?(row['status']) },
                 'left out' => ->(row) { %w[dropped excluded].include?(row['status']) } }.freeze
      TOP = 4 # values shown per tag or field before "…"
      PRESENCE = { true => 'present', false => 'absent' }.freeze

      def initialize(system:)
        @system = system
        @definition = system.definition
        @rows = Store.sets(@definition).flat_map { |set| Store.rows(@definition, set).map { |row| [set, row] } }
        @running = @rows.map(&:last).select { |row| Store.runs?(row) }
      end

      def report
        report = Report.new.line(title)
        report.heading('Cases').table(['', 'dev', 'test', 'total'], case_rows)
        report.blank.concat(diversity)
      end

      # The run a mode would make: what is cached, what it would call, and its estimate.
      def plan(mode:, runners:)
        estimates = runners.map(&:estimate)
        items = runners.first.items
        selected = items.size
        to_call = estimates.sum { |e| e['cases'] }
        variants = @definition.variants.keys
        cases = items.map(&:id).uniq.size
        each = variants.any? ? " × #{variants.size} variants (#{variants.join(', ')})" : ''
        repeat = runners.size > 1 ? " × #{runners.size} replicates" : ''
        twins = items.select(&:twin).map(&:id).uniq.size # rows, like `cases`, not rows × variants
        report = Report.new.heading('Plan')
        pool = mode.to_s == 'quick' ? ' dev' : nil
        report.line("#{mode}: #{cases}#{pool} cases#{each}#{repeat}, " \
                    "#{(selected * runners.size) - to_call} cached, #{to_call} to call")
        report.line("  #{twins} of them are twin pairs: two calls each") if twins.positive?
        report.line("  #{Overview.cost(estimates)}") if to_call.positive?
        judge = judge_line(runners, to_call)
        report.line("  #{judge}") if judge
        report
      end

      # One line for the estimates of any number of runners (one eval, or a whole suite).
      def self.cost(estimates)
        tokens = estimates.sum { |e| e['input_tokens'] + e['output_tokens'] }
        usd = estimates.map { |e| e['usd'] }
        seconds = estimates.map { |e| e['seconds'] }
        money = usd.all? ? format('~$%.2f', usd.sum) : 'cost unknown (add a price in evals/config.yml)'
        time = seconds.all? ? "~#{Progress.clock(seconds.sum)}" : 'time unknown until a case has run'
        "~#{estimates.sum { |e| e['calls'] }} calls · ~#{tokens} tokens · #{money} · #{time}"
      end

      # Judge calls are paid too: a rubric case needs one, a `judge: true` field one when its check fails.
      # Cached cases of every replicate count, since the run judges them all.
      private

      def title
        git = @system.git
        model = [@system.provider, @system.model].compact.join('/')
        [@definition.name, model.empty? ? 'default model' : model, "code #{@system.code_hash[0, 8]}",
         "#{git['branch']} #{git['sha'].to_s[0, 8]}#{' (uncommitted changes)' if git['dirty']}"].join(' · ')
      end

      def case_rows
        STATES.filter_map do |state, matches|
          rows = @rows.map(&:last).select(&matches)
          next if rows.empty? && state != 'run'

          dev = rows.count { |r| r['pool'] == 'dev' }
          test = rows.count { |r| r['pool'] == 'test' }
          [state, dev, test, rows.size]
        end
      end

      def diversity
        report = Report.new
        return report.line('no case runs yet: add rows to a set (see evals/README.md)') if @running.empty?

        pairs = []
        sets = @rows.select { |_set, row| Store.runs?(row) }.map(&:first).tally
        pairs << ['sets', tally(sets)] if sets.size > 1
        difficulty = @running.map { |r| tags(r)['difficulty'].then { |d| d.nil? ? 'untagged' : d.to_s } }
        pairs << ['difficulty', tally(difficulty.tally)]
        report.pairs(pairs + tag_pairs + gold_pairs)
      end

      # A `false` tag is a value like any other, so it is counted, not skipped.
      def tag_pairs
        all = @running.map { |r| tags(r) }
        (all.flat_map(&:keys).uniq - ['difficulty']).sort.map do |key|
          ["tag #{key}", tally(all.select { |t| t.key?(key) }.map { |t| t[key].to_s }.tally)]
        end
      end

      # Tags are free form; only an object's keys are tags (a list or a text has none).
      def tags(row)
        row['tags'].is_a?(Hash) ? row['tags'] : {}
      end

      def gold_pairs
        return [['gold', 'graded by a custom block']] if @definition.custom_grader?

        case @definition.grader
        when 'fields' then field_pairs
        when 'band', 'rubric'
          [['gold bands', tally(@running.filter_map { |r| r.dig('gold', 'band')&.inspect }.tally)]]
        when 'list'
          types = @running.flat_map { |r| Array(r.dig('gold', 'checks')).map { |c| c['type'] } }
          [['list checks', tally(types.tally)]]
        else []
        end
      end

      # Per field: the categories its gold asks for, or how often it must be present or absent.
      def field_pairs
        specs = Hash.new { |h, k| h[k] = [] }
        @running.each { |r| (r.dig('gold', 'fields') || {}).each { |name, spec| specs[name] << spec } }
        specs.sort.map do |name, field_specs|
          labels = field_specs.map { |spec| Matrices.gold_label(spec) }
          detail = if Matrices.categorical?(labels)
                     "#{labels.uniq.size} values (#{tally(labels.tally)})"
                   else
                     present = field_specs.map { |s| PRESENCE.fetch(s['present'], 'optional') }
                     checks = field_specs.filter_map { |s| s['check'] }.uniq
                     "#{tally(present.tally)}#{" · checks #{checks.join(', ')}" if checks.any?}"
                   end
          ["field #{name}", detail]
        end
      end

      def judge_line(runners, to_call)
        return if @definition.custom_grader?

        waiting = runners.sum { |runner| runner.unjudged.size }
        new_calls = @definition.grader == 'rubric' ? to_call : 0
        judged_fields = @running.any? { |r| (r.dig('gold', 'fields') || {}).values.any? { |s| s['judge'] } }
        return if waiting.zero? && new_calls.zero? && !judged_fields

        parts = []
        parts << "#{waiting} cached case(s) wait for a verdict" if waiting.positive?
        parts << "#{new_calls} rubric verdict(s) for the new cases" if new_calls.positive?
        parts << 'judge: true fields are judged only where their check fails' if judged_fields
        "judge (#{Eval.config.dig('judge', 'model') || 'not configured'}): #{parts.join('; ')}"
      end

      def tally(counts)
        sorted = counts.sort_by { |value, n| [-n, value.to_s] }
        shown = sorted.first(TOP).map { |value, n| "#{value} #{n}" }
        shown << "… #{sorted.size - TOP} more" if sorted.size > TOP
        shown.join(' · ')
      end
    end
  end
end

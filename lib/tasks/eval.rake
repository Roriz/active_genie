# frozen_string_literal: true

# Evals for your own LLM features. See the README that `active_genie:eval:install` writes to evals/.
#
#   rake active_genie:eval EVAL=<name>             the dev pool (MODE=full for every case, REPEAT=n)
#
# A run first shows the eval and what it would call, cost and take, then asks before spending.
Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)

module ActiveGenieEvalTasks
  module_function

  def eval_lib
    require_relative '../active_genie'
    require_relative '../active_genie/eval'
    ActiveGenie::Eval
  end

  def definition
    name = ENV.fetch('EVAL') { abort "EVAL=<name> is required, one of: #{eval_lib.load!.keys.sort.join(', ')}" }
    eval_lib.fetch(name)
  end

  def guard
    yield
  rescue ActiveGenie::Eval::Error => e
    abort e.message
  end

  def check!(name)
    check = eval_lib::Check.new.run(only: name)
    return if check.ok?

    puts check.report
    abort 'active_genie:eval:check failed; fix the data before spending money.'
  end

  # One eval's run, planned: what it would call before anything is asked.
  Planned = Struct.new(:definition, :system, :items, :runners, keyword_init: true)

  # EVAL=<name>, EVAL=a,b or EVAL=all.
  def definitions
    names = ENV.fetch('EVAL') { abort "EVAL=<name> (or a,b or all) is required, one of: #{eval_lib.load!.keys.sort.join(', ')}" }
    return eval_lib.load!.values.sort_by(&:name) if names == 'all'

    names.split(',').map { |name| eval_lib.fetch(name.strip) }
  end

  # Shows each eval and the plan, asks once before spending (YES=1 skips the question; without a
  # terminal, YES=1 is required), runs with a progress line, then prints and saves each report. A
  # suite (several evals) ends with one summary table.
  def run(mode, replicates: 1)
    definitions = self.definitions
    definitions.each { |definition| check!(definition.name) }
    plans = definitions.filter_map { |definition| plan(definition, mode, replicates) }
    abort "No #{mode} cases to run." if plans.empty?
    puts "All #{plans.size} evals: #{eval_lib::Overview.cost(plans.flat_map(&:runners).map(&:estimate))}", '' if plans.size > 1
    return unless confirmed?(plans.flat_map(&:runners))

    boards = plans.map do |planned|
      puts "Running #{planned.definition.name}..." if plans.size > 1
      planned.runners.each { |runner| runner.run!(judge: true) }
      puts
      report(planned.system, planned.items, mode, exit_on_stop: plans.size == 1)
    end
    summary(boards, mode) if plans.size > 1
  end

  def plan(definition, mode, replicates)
    system = eval_lib::System.from_env(definition)
    items = eval_lib::Selection.call(definition, mode)
    overview = eval_lib::Overview.new(system:)
    if items.empty?
      puts overview.report.to_text, '', "No #{mode} cases in #{definition.name} yet.", ''
      return
    end

    runners = (1..replicates).map { |r| eval_lib::Runner.new(system:, items:, replicate: r) }
    puts overview.report.concat(overview.plan(mode:, runners:)).to_text, ''
    Planned.new(definition:, system:, items:, runners:)
  end

  # One row per eval (and per variant), and the mean of their rates: each counts the same, however many
  # cases it has.
  def summary(boards, mode)
    rows = boards.flat_map { |board| board.summary_rows.map { |row| row.merge(verdict: board.verdict) } }
    pct = ->(v) { v.nil? ? '-' : format('%.1f%%', v * 100) }
    table = rows.map do |row|
      [row[:name], row[:cases], pct.call(row[:rate]), row[:delta] ? format('%+.1f', row[:delta] * 100) : '-',
       mode == 'quick' ? row[:verdict] : '']
    end
    rates = rows.filter_map { |row| row[:rate] }
    report = eval_lib::Report.new.heading("Summary (#{mode})").table(%w[eval cases rate delta verdict], table)
    report.line("mean of #{rates.size} rates: #{pct.call(rates.sum / rates.size)}") if rates.any?
    puts '', report.to_text
    exit 1 if mode == 'quick' && boards.any? { |b| b.verdict == 'STOP' }
  end

  def confirmed?(runners)
    paid = runners.sum { |r| r.estimate['cases'] }.positive? || runners.any? { |r| r.unjudged.any? }
    return true if !paid || ENV['YES'] == '1'

    unless $stdin.tty? && $stdout.tty?
      puts 'Nothing was called. Re-run with YES=1 to spend it.'
      return false
    end

    print 'Run it? [y/N] '
    return true if $stdin.gets.to_s.strip.match?(/\Ay(es)?\z/i)

    puts 'Nothing was called.'
    false
  end

  # REPEAT=n: how many replicates to run, 1 or more.
  def replicates
    value = ENV.fetch('REPEAT', '1')
    count = Integer(value, 10, exception: false)
    abort "REPEAT is a number of runs, 1 or more, not #{value.inspect}" unless count&.positive?
    count
  end

  # The report goes to the terminal and, next to the run, to report-<mode>.md (pasteable into a pull
  # request) and report-<mode>.json.
  def report(system, items, mode, exit_on_stop: true)
    board = eval_lib::Scoreboard.new(system:, items:, mode:)
    puts board.report
    FileUtils.mkdir_p(system.run_root)
    markdown = File.join(system.run_root, "report-#{mode}.md")
    File.write(markdown, board.markdown)
    eval_lib::Store.write_json(File.join(system.run_root, "report-#{mode}.json"),
                               { 'text' => board.report, 'verdict' => board.verdict })
    puts '', "report: #{markdown.delete_prefix("#{eval_lib.app_root}/")}"
    exit 1 if exit_on_stop && mode == 'quick' && board.verdict == 'STOP'
    board
  end

  # With EVAL=<name>: that eval's size and diversity. Without: one line per eval.
  def status
    return puts eval_lib::Overview.new(system: eval_lib::System.from_env(definition)).report.to_text if ENV['EVAL']

    eval_lib.load!.each_value.sort_by(&:name).each do |definition|
      counts = eval_lib::Store.rows(definition).map { |r| "#{r['pool'] || '-'}/#{r['status'] || '-'}" }.tally
      system = eval_lib::System.from_env(definition)
      saved = system.baseline_replicates.any? ? "baseline for #{system.name}" : "no baseline for #{system.name}"
      puts format('%-28s %s; %s', definition.name, counts.sort.map { |k, n| "#{k} #{n}" }.join(', '), saved)
    end
  end
end

namespace :active_genie do
  desc 'Run EVAL=<name> (or a,b or all): shows the cases and the estimate, asks, runs, reports. MODE=quick|full'
  task eval: :environment do
    mode = ENV.fetch('MODE', 'quick')
    abort "MODE is quick or full, not #{mode.inspect}" unless %w[quick full].include?(mode)

    ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.run(mode, replicates: ActiveGenieEvalTasks.replicates) }
  end

  namespace :eval do
    desc 'Write evals/config.yml, evals/README.md and evals/.gitignore (never overwrites)'
    task :install do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.eval_lib::Scaffold.install }
    end

    desc 'Start a new eval: evals/<name>/eval.rb and a starting datasets.jsonl. Usage: active_genie:eval:new[name]'
    task :new, [:name] do |_t, args|
      name = args[:name] || ENV.fetch('EVAL') { abort 'Usage: rake "active_genie:eval:new[ticket_router]"' }
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.eval_lib::Scaffold.new_eval(name) }
    end

    desc 'Free: check evals/config.yml and every eval, datasets.jsonl and gold.jsonl. EVAL=<name> for one'
    task check: :environment do
      check = ActiveGenieEvalTasks.eval_lib::Check.new.run(only: ENV.fetch('EVAL', nil))
      puts check.report
      exit 1 unless check.ok?
    end

    desc 'Free: cases per eval and which baselines exist; EVAL=<name> for its size and diversity'
    task status: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.status }
    end

    desc 'Paid: the dev pool of EVAL=<name> against its baseline -> GO / LOOK / STOP (asks first)'
    task quick: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.run('quick', replicates: ActiveGenieEvalTasks.replicates) }
    end

    desc 'Paid: every case of EVAL=<name>. REPEAT=3 measures the noise floor (asks first)'
    task full: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.run('full', replicates: ActiveGenieEvalTasks.replicates) }
    end

    desc 'Free: re-print the report of EVAL=<name> from cached outputs. MODE=quick|full'
    task report: :environment do
      ActiveGenieEvalTasks.guard do
        definition = ActiveGenieEvalTasks.definition
        mode = ENV.fetch('MODE', 'full')
        system = ActiveGenieEvalTasks.eval_lib::System.from_env(definition)
        ActiveGenieEvalTasks.report(system, ActiveGenieEvalTasks.eval_lib::Selection.call(definition, mode), mode)
      end
    end

    desc 'Free: promote the complete full run of EVAL=<name> to its committed baseline. BY=name'
    task save: :environment do
      ActiveGenieEvalTasks.guard do
        lib = ActiveGenieEvalTasks.eval_lib
        definition = ActiveGenieEvalTasks.definition
        system = lib::System.from_env(definition)
        saved_by = ENV['BY'] || lib.git('config', 'user.name')
        lib::Baseline.save!(system, lib::Selection.call(definition, 'full'), saved_by:, force: ENV['FORCE'] == '1')
        puts "Saved the baseline of #{definition.name} for #{system.name}."
      end
    end

    desc 'Free: print the drafts of EVAL=<name> without their gold, for a blind labeler'
    task blind: :environment do
      ActiveGenieEvalTasks.guard do
        lib = ActiveGenieEvalTasks.eval_lib
        lib::Labeling.blind(ActiveGenieEvalTasks.definition).each do |row|
          puts JSON.generate(row)
        end
      end
    end

    desc 'Free: compare the blind labels of EVAL=<name> with the gold and write each draft\'s status'
    task label: :environment do
      ActiveGenieEvalTasks.guard do
        definition = ActiveGenieEvalTasks.definition
        result = ActiveGenieEvalTasks.eval_lib::Labeling.merge(definition)
        waiting = result[:draft].positive? ? ", #{result[:draft]} still waiting for a blind pass" : ''
        dropped = result[:dropped].positive? ? ", #{result[:dropped]} dropped as unclear" : ''
        puts "#{definition.name}: #{result[:confirmed]} confirmed, #{result[:queued]} waiting for a decision#{dropped}#{waiting}"
        result[:queue].each do |q|
          puts "  #{q['id']}.#{q['field']}: gold #{JSON.generate(q['gold'])} | A #{q['pass_a'].inspect} | B #{q['pass_b'].inspect}"
        end
        puts 'Settle a queued row: edit its gold if needed and set "status": "decided".' if result[:queued].positive?
      end
    end
  end
end

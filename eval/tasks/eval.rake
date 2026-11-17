# frozen_string_literal: true

require_relative '../lib/genie_eval'

# Paid tasks print the cost of the cases that are not cached yet and stop unless YES=1.
# Common env: PROVIDER, MODEL (default: the dev model in eval/config.json), CELLS=a,b (subset).
module GenieEvalTasks
  module_function

  def system = GenieEval::System.from_env
  def cells = ENV['CELLS']&.split(',')&.map(&:strip)

  def items(mode)
    GenieEval::Selection.call(mode, cells:, all_dev: ENV['ALL_DEV'] == '1')
  end

  def check!
    check = GenieEval::Check.new.run
    return if check.ok?

    puts check.report
    abort 'eval:check failed; fix the data before spending money.'
  end

  def run(mode, replicates: 1)
    check!
    sys = system
    selected = items(mode)
    abort "No cases selected for #{mode}." if selected.empty?

    runners = (1..replicates).map { |r| GenieEval::Runner.new(system: sys, items: selected, replicate: r) }
    return unless pay?(sys, runners)

    runners.each(&:run!)
    report(sys, selected, mode)
  end

  def pay?(sys, runners)
    estimates = runners.map(&:estimate)
    cases = estimates.sum { |e| e['cases'] }
    return true if cases.zero?

    tokens = estimates.sum { |e| e['input_tokens'] + e['output_tokens'] }
    puts "#{sys.describe}: #{cases} case runs to call, ~#{tokens} tokens, #{cost_text(sys, estimates)}."
    return true if ENV['YES'] == '1'

    puts 'Nothing was called. Re-run with YES=1 to run it.'
    false
  end

  def cost_text(sys, estimates)
    if GenieEval::Transports.transport?(sys.provider)
      return "no API billing (runs on your local #{sys.provider} login and uses its quota)"
    end

    usd = estimates.map { |e| e['usd'] }
    usd.all? ? format('about $%.2f', usd.sum) : 'cost unknown (no price for this model in eval/config.json)'
  end

  def report(sys, selected, mode)
    board = GenieEval::Scoreboard.new(system: sys, items: selected, mode:)
    text = board.report
    puts text
    GenieEval::Store.write_json(File.join(sys.run_root, "report-#{mode}.json"),
                                { 'text' => text, 'verdict' => board.verdict })
    exit 1 if mode == 'quick' && board.verdict == 'STOP'
  end

  def status
    rows = GenieEval::Selection.all_items
    rows.group_by(&:cell).each do |cell, cell_items|
      counts = cell_items.group_by { |i| [i.pool, i.role || '-'] }.transform_values(&:size)
      puts format('%-28s %s', cell, counts.sort.map { |(pool, role), n| "#{pool}/#{role} #{n}" }.join(', '))
    end
    puts
    GenieEval.config.fetch('release').each do |entry|
      sys = GenieEval::System.new(provider: entry['provider'], model: entry['model'])
      saved = File.exist?(File.join(sys.baseline_dir, 'BASE.json')) ? 'baseline saved' : 'no baseline'
      puts format('%-40s %s', sys.name, saved)
    end
  end
end

namespace :eval do
  desc 'Free: check eval data integrity and lint the prompts in lib/ (no model calls)'
  task :check do
    check = GenieEval::Check.new.run
    puts check.report
    exit 1 unless check.ok?
  end

  desc 'Free: cases per cell, pool and role, and which baselines exist'
  task :status do
    GenieEvalTasks.status
  end

  desc 'Paid: dev pool (3 hard + 2 canaries per cell once roles exist) -> GO / LOOK / STOP. YES=1 to spend'
  task :quick do
    GenieEvalTasks.run('quick')
  end

  desc 'Paid: every case, weighted score with CIs. REPEAT=3 measures the noise floor. YES=1 to spend'
  task :full do
    GenieEvalTasks.run('full', replicates: Integer(ENV.fetch('REPEAT', '1')))
  end

  desc 'Free: re-print the report from cached outputs. MODE=quick|full'
  task :report do
    mode = ENV.fetch('MODE', 'full')
    GenieEvalTasks.report(GenieEvalTasks.system, GenieEvalTasks.items(mode), mode)
  end

  desc 'Free: promote the complete full run of this lib/ to the committed baseline. BY=name'
  task :save do
    sys = GenieEvalTasks.system
    saved_by = ENV['BY'] || GenieEval.git('config', 'user.name')
    GenieEval::Baseline.save!(sys, GenieEvalTasks.items('full'), saved_by:, force: ENV['FORCE'] == '1')
    puts "Saved baseline for #{sys.name} at #{sys.baseline_dir.delete_prefix("#{GenieEval::REPO}/")}."
    puts 'Dev-pool roles (hard / canary) updated in eval/pools.jsonl.' if sys.dev?
  rescue GenieEval::Error => e
    abort e.message
  end
end

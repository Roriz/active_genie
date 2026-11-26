# frozen_string_literal: true

require_relative '../lib/genie_eval'

# Paid tasks print the cost of the cases that are not cached yet and stop unless YES=1.
# Common env: PROVIDER, MODEL (default: the dev model in eval/config.json), CELLS=a,b (subset).
module GenieEvalTasks
  module_function

  def system = GenieEval::System.from_env
  def cells = ENV['CELLS']&.split(',')&.map(&:strip)

  def set
    ENV.fetch('SET') { abort "SET=<set> is required, one of: #{GenieEval::Store.sets.join(', ')}" }
  end

  def items(mode)
    GenieEval::Selection.call(mode, cells:)
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

    # The judge is paid too: without YES=1 it stays off, even when every case is already cached.
    runners.each { |runner| runner.run!(judge: ENV['YES'] == '1') }
    report(sys, selected, mode)
  end

  def pay?(sys, runners)
    estimates = runners.map(&:estimate)
    cases = estimates.sum { |e| e['cases'] }
    return true if cases.zero?

    usd = estimates.map { |e| e['usd'] }
    cost = usd.all? ? format('about $%.2f', usd.sum) : 'cost unknown (no price for this model in eval/config.json)'
    tokens = estimates.sum { |e| e['input_tokens'] + e['output_tokens'] }
    puts "#{sys.describe}: #{cases} case runs to call, ~#{tokens} tokens, #{cost}."
    return true if ENV['YES'] == '1'

    puts 'Nothing was called. Re-run with YES=1 to spend it.'
    false
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
    GenieEval::Selection.all_items.group_by(&:cell).each do |cell, cell_items|
      puts format('%-28s %s', cell, cell_items.map { |i| i.pool || '-' }.tally.sort.map { |pool, n| "#{pool} #{n}" }.join(', '))
    end
    puts
    GenieEval::Store.sets.each do |set|
      counts = GenieEval::Store.rows(set).map { |r| r['status'] || '-' }.tally
      puts format('%-28s %s', set, counts.sort.map { |status, n| "#{status} #{n}" }.join(', '))
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

  desc 'Free: cases per cell and pool, rows per set and status, and which baselines exist'
  task :status do
    GenieEvalTasks.status
  end

  desc 'Paid: the dev pool against the baseline -> GO / LOOK / STOP. YES=1 to spend'
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

  desc 'Free: compare the blind labels with the gold and write each drafted row\'s status. SET=<set>'
  task :label do
    set = GenieEvalTasks.set
    result = GenieEval::Labeling.merge(set)
    dropped = result[:dropped].positive? ? ", #{result[:dropped]} dropped as unclear" : ''
    drafts = result[:draft].positive? ? ", #{result[:draft]} still waiting for a blind pass" : ''
    puts "#{set}: #{result[:confirmed]} confirmed, #{result[:queued]} waiting for a decision#{dropped}#{drafts}"
    result[:queue].each do |q|
      puts "  #{q['id']}.#{q['field']}: gold #{JSON.generate(q['gold'])} | A #{q['pass_a'].inspect} | B #{q['pass_b'].inspect}"
    end
    if result[:queued].positive?
      puts 'Settle a queued row in eval/sets/: edit its gold if needed and set "status": "decided".'
    end
  rescue GenieEval::Error => e
    abort e.message
  end

  desc 'Free: print the rows a blind labeler should label, without their gold. SET=<set>'
  task :blind do
    GenieEval::Labeling.blind(GenieEvalTasks.set).each { |row| puts JSON.generate(row) }
  rescue GenieEval::Error => e
    abort e.message
  end

  desc 'Free: promote the complete full run of this lib/ to the committed baseline. BY=name'
  task :save do
    sys = GenieEvalTasks.system
    saved_by = ENV['BY'] || GenieEval.git('config', 'user.name')
    GenieEval::Baseline.save!(sys, GenieEvalTasks.items('full'), saved_by:, force: ENV['FORCE'] == '1')
    puts "Saved baseline for #{sys.name} at #{sys.baseline_dir.delete_prefix("#{GenieEval::REPO}/")}."
  rescue GenieEval::Error => e
    abort e.message
  end
end

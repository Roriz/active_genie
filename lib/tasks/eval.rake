# frozen_string_literal: true

# Evals for your own LLM features. See the README that `active_genie:eval:install` writes to evals/.
# Paid tasks print the cost of the cases that aren't cached yet and stop unless YES=1.
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

  def set
    ENV.fetch('SET') { abort "SET=<set> is required, one of: #{eval_lib::Store.sets(definition).join(', ')}" }
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

  def run(mode, replicates: 1)
    definition = self.definition
    check!(definition.name)
    system = eval_lib::System.from_env(definition)
    items = eval_lib::Selection.call(definition, mode)
    abort "No #{mode} cases in #{definition.name}." if items.empty?

    runners = (1..replicates).map { |r| eval_lib::Runner.new(system:, items:, replicate: r) }
    return unless pay?(system, runners)

    runners.each { |runner| runner.run!(judge: ENV['YES'] == '1') }
    report(system, items, mode)
  end

  def pay?(system, runners)
    estimates = runners.map(&:estimate)
    cases = estimates.sum { |e| e['cases'] }
    judge_only = cases.zero?
    unless judge_only
      usd = estimates.map { |e| e['usd'] }
      cost = usd.all? ? format('about $%.2f', usd.sum) : 'cost unknown (add a price in evals/config.yml)'
      tokens = estimates.sum { |e| e['input_tokens'] + e['output_tokens'] }
      puts "#{system.describe}: #{cases} case runs to call, ~#{tokens} tokens, #{cost}."
    end
    return true if judge_only || ENV['YES'] == '1'

    puts 'Nothing was called. Re-run with YES=1 to spend it.'
    false
  end

  def report(system, items, mode)
    board = eval_lib::Scoreboard.new(system:, items:, mode:)
    text = board.report
    puts text
    eval_lib::Store.write_json(File.join(system.run_root, "report-#{mode}.json"),
                               { 'text' => text, 'verdict' => board.verdict })
    exit 1 if mode == 'quick' && board.verdict == 'STOP'
  end

  def status
    eval_lib.load!.each_value.sort_by(&:name).each do |definition|
      store = eval_lib::Store
      counts = store.sets(definition).flat_map { |s| store.rows(definition, s) }
                                     .map { |r| "#{r['pool'] || '-'}/#{r['status'] || '-'}" }.tally
      system = eval_lib::System.from_env(definition)
      saved = system.baseline_replicates.any? ? "baseline for #{system.name}" : "no baseline for #{system.name}"
      puts format('%-28s %s; %s', definition.name, counts.sort.map { |k, n| "#{k} #{n}" }.join(', '), saved)
    end
  end
end

namespace :active_genie do
  namespace :eval do
    desc 'Write evals/config.yml, evals/README.md and evals/.gitignore (never overwrites)'
    task :install do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.eval_lib::Scaffold.install }
    end

    desc 'Start a new eval: evals/<name>/eval.rb and a starting set. Usage: active_genie:eval:new[name]'
    task :new, [:name] do |_t, args|
      name = args[:name] || ENV.fetch('EVAL') { abort 'Usage: rake "active_genie:eval:new[ticket_router]"' }
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.eval_lib::Scaffold.new_eval(name) }
    end

    desc 'Free: check evals/config.yml and every eval, set and labels file. EVAL=<name> for one'
    task check: :environment do
      check = ActiveGenieEvalTasks.eval_lib::Check.new.run(only: ENV.fetch('EVAL', nil))
      puts check.report
      exit 1 unless check.ok?
    end

    desc 'Free: cases per eval, pool and status, and which baselines exist'
    task status: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.status }
    end

    desc 'Paid: the dev pool of EVAL=<name> against its baseline -> GO / LOOK / STOP. YES=1 to spend'
    task quick: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.run('quick') }
    end

    desc 'Paid: every case of EVAL=<name>. REPEAT=3 measures the noise floor. YES=1 to spend'
    task full: :environment do
      ActiveGenieEvalTasks.guard { ActiveGenieEvalTasks.run('full', replicates: Integer(ENV.fetch('REPEAT', '1'))) }
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

    desc 'Free: print the drafts of EVAL=<name> SET=<set> without their gold, for a blind labeler'
    task blind: :environment do
      ActiveGenieEvalTasks.guard do
        lib = ActiveGenieEvalTasks.eval_lib
        lib::Labeling.blind(ActiveGenieEvalTasks.definition, ActiveGenieEvalTasks.set).each do |row|
          puts JSON.generate(row)
        end
      end
    end

    desc 'Free: compare the blind labels of EVAL=<name> SET=<set> with the gold and write each draft\'s status'
    task label: :environment do
      ActiveGenieEvalTasks.guard do
        set = ActiveGenieEvalTasks.set
        result = ActiveGenieEvalTasks.eval_lib::Labeling.merge(ActiveGenieEvalTasks.definition, set)
        waiting = result[:draft].positive? ? ", #{result[:draft]} still waiting for a blind pass" : ''
        dropped = result[:dropped].positive? ? ", #{result[:dropped]} dropped as unclear" : ''
        puts "#{set}: #{result[:confirmed]} confirmed, #{result[:queued]} waiting for a decision#{dropped}#{waiting}"
        result[:queue].each do |q|
          puts "  #{q['id']}.#{q['field']}: gold #{JSON.generate(q['gold'])} | A #{q['pass_a'].inspect} | B #{q['pass_b'].inspect}"
        end
        puts 'Settle a queued row: edit its gold if needed and set "status": "decided".' if result[:queued].positive?
      end
    end
  end
end

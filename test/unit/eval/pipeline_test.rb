# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/mock'
require 'tmpdir'
require_relative '../../../eval/lib/genie_eval'

# End to end without a model: run -> cache -> report -> save baseline -> roles -> regression verdict.
class GenieEvalPipelineTest < Minitest::Test
  Store = GenieEval::Store

  def setup
    @dir = Dir.mktmpdir
    GenieEval.root = @dir
    write_dataset
    @system = GenieEval::System.new(provider: 'fake', model: 'fake-model')
    @answers = { 'good' => 80, 'bad' => 10 }
  end

  def teardown
    GenieEval.root = nil
    FileUtils.rm_rf(@dir)
  end

  def test_quick_run_baseline_and_regression
    quick = GenieEval::Selection.call('quick')

    assert_equal 3, quick.size, 'without roles, quick runs the whole dev pool'
    assert_equal 3, runner(quick).estimate['cases']
    assert_match(/MISSING 3 of 3 cases/, scoreboard(quick).report, 'cases not run yet are not failures')
    refute_match(/0\.0%/, scoreboard(quick).report)

    run_cases(quick)

    assert_empty runner(quick).pending, 'records are cached'
    assert_equal 'NO BASELINE', scoreboard(quick).verdict

    GenieEval::Baseline.save!(@system, GenieEval::Selection.call('full'), saved_by: 'test', force: true)
    roles = Store.pools.to_h { |p| [p['id'], p['role']] }

    assert_equal({ 'good' => 'canary', 'bad' => 'hard', 'pair' => 'canary' }, roles)

    FileUtils.rm_rf(@system.run_root)
    @answers['good'] = 5 # the canary now fails
    run_cases(GenieEval::Selection.call('quick'))
    board = scoreboard(GenieEval::Selection.call('quick'))

    assert_equal 'STOP', board.verdict
    assert_match %r{BROKE\s+scorer.by_jury_bench/good \(canary\)}, board.report
  end

  def test_errors_are_recorded_and_retried
    items = GenieEval::Selection.call('quick')
    failing = ->(_cell, _input) { raise 'provider down' }
    GenieEval::Runner.stub(:configure!, nil) do
      GenieEval::Executor.stub(:call, failing) { runner(items).run! }
    end

    assert_equal 3, runner(items).pending.size
    assert_match(/ERROR\s+.*provider down/, scoreboard(items).report)
  end

  def test_report_shows_the_gap_of_scorer_bias_pairs
    add_scorer_case('paired', { 'text' => 'plain', 'twin' => 'by a professor', 'criteria' => 'c' },
                    { 'band' => [50, 100], 'max_gap' => 10 }, tags: { 'bias' => 'authority' })
    @answers.merge!('plain' => 60, 'by a professor' => 66)
    items = GenieEval::Selection.call('quick')
    run_cases(items)

    assert_match(/scorer bias pairs: mean \|gap\| 6\.0 points; mean gap by bias \(twin - text\): authority \+6\.0 \(1\)/,
                 scoreboard(items).report)
  end

  def test_executor_scores_the_twin_with_the_same_criteria_and_juries
    seen = []
    fake = lambda do |text, criteria, juries:, **|
      seen << [text, criteria, juries]
      ActiveGenie::Result.new(data: text.size, reasoning: 'r', metadata: {})
    end
    picked = []
    pick = lambda do |text, _criteria, **|
      picked << text
      ActiveGenie::Result.new(data: %w[Editor Linguist], reasoning: 'r', metadata: {})
    end
    record = ActiveGenie::Lister.stub(:with_juries, pick) do
      ActiveGenie::Scorer.stub(:by_jury_bench, fake) do
        GenieEval::Executor.call('scorer.by_jury_bench', { 'text' => 'abc', 'twin' => 'abcde', 'criteria' => 'c' })
      end
    end

    assert_equal %w[abc], picked, 'juries are picked once, from the text'
    assert_equal [['abc', 'c', %w[Editor Linguist]], ['abcde', 'c', %w[Editor Linguist]]], seen
    assert_equal([3, 5], record.values_at('output', 'twin').map { |r| r['data'] })
    assert_equal %w[Editor Linguist], record['juries']
  end

  def test_check_validates_scorer_bias_pairs
    add_scorer_case('ok', { 'text' => 't', 'twin' => 't!', 'criteria' => 'c' }, { 'band' => [0, 100], 'max_gap' => 10 })
    add_scorer_case('null_gap', { 'text' => 't', 'twin' => 't!', 'criteria' => 'c' }, { 'band' => [0, 100], 'max_gap' => nil })
    add_scorer_case('no_gap', { 'text' => 't', 'twin' => 't!', 'criteria' => 'c' }, { 'band' => [0, 100] })
    add_scorer_case('same', { 'text' => 't', 'twin' => 't', 'criteria' => 'c' }, { 'band' => [0, 100], 'max_gap' => 10 })
    add_scorer_case('nil_twin', { 'text' => 't', 'twin' => nil, 'criteria' => 'c' }, { 'band' => [0, 100], 'max_gap' => 10 })

    errors = GenieEval::Check.new.run.errors.join("\n")

    refute_match %r{/ok:}, errors
    assert_match %r{/null_gap: max_gap must be a number}, errors
    assert_match %r{/no_gap: a case has a twin exactly when}, errors
    assert_match %r{/same: twin must be a non-empty text}, errors
    assert_match %r{/nil_twin: twin must be a non-empty text}, errors
  end

  private

  def add_scorer_case(id, input, gold, tags: {})
    cell = 'scorer.by_jury_bench'
    Store.write_jsonl(GenieEval.path('cases', "#{cell}.jsonl"),
                      Store.cases(cell) + [{ 'id' => id, 'cell' => cell, 'tags' => tags, 'input' => input }])
    Store.write_jsonl(GenieEval.path('gold', "#{cell}.jsonl"), Store.gold(cell).values + [{ 'id' => id, 'gold' => gold }])
    Store.write_pools(Store.pools + [{ 'cell' => cell, 'id' => id, 'pool' => 'dev', 'role' => nil }])
  end

  def runner(items)
    GenieEval::Runner.new(system: @system, items:, concurrency: 2, io: StringIO.new)
  end

  def run_cases(items)
    fake = lambda do |cell, input|
      if cell.start_with?('comparator')
        next { 'orders' => { 'ab' => { 'winner' => 'a' }, 'ba' => { 'winner' => 'a' } } }
      end

      record = { 'output' => { 'data' => @answers.fetch(input['text']), 'reasoning' => 'r' } }
      record['twin'] = { 'data' => @answers.fetch(input['twin']), 'reasoning' => 'r' } if input['twin']
      record
    end
    GenieEval::Runner.stub(:configure!, nil) do
      GenieEval::Executor.stub(:call, fake) { runner(items).run! }
    end
  end

  def scoreboard(items)
    GenieEval::Scoreboard.new(system: @system, items:, mode: 'quick')
  end

  def write_dataset
    config = JSON.parse(File.read(File.join(GenieEval::ROOT, 'config.json')))
    config['dev'] = { 'provider' => 'fake', 'model' => 'fake-model' }
    config['usd_per_million_tokens'] = { 'fake-model' => { 'input' => 1.0, 'output' => 1.0 } }
    Store.write_json(GenieEval.path('config.json'), config)
    Store.write_json(GenieEval.path('cells.json'), [
                       { 'id' => 'scorer.by_jury_bench', 'grader' => 'scorer', 'weight' => 1 },
                       { 'id' => 'comparator.by_debate', 'grader' => 'comparator', 'weight' => 1 }
                     ])
    scorer = %w[good bad].map { |id| { 'id' => id, 'cell' => 'scorer.by_jury_bench', 'input' => { 'text' => id, 'criteria' => 'c' } } }
    Store.write_jsonl(GenieEval.path('cases', 'scorer.by_jury_bench.jsonl'), scorer)
    Store.write_jsonl(GenieEval.path('gold', 'scorer.by_jury_bench.jsonl'),
                      %w[good bad].map { |id| { 'id' => id, 'gold' => { 'band' => [50, 100] } } })
    Store.write_jsonl(GenieEval.path('cases', 'comparator.by_debate.jsonl'), [
                        { 'id' => 'pair', 'cell' => 'comparator.by_debate',
                          'input' => { 'player_a' => 'A', 'player_b' => 'B', 'criteria' => 'c' } }
                      ])
    Store.write_jsonl(GenieEval.path('gold', 'comparator.by_debate.jsonl'), [{ 'id' => 'pair', 'gold' => { 'winner' => 'a' } }])
    Store.write_pools([
                        { 'cell' => 'scorer.by_jury_bench', 'id' => 'good', 'pool' => 'dev', 'role' => nil },
                        { 'cell' => 'scorer.by_jury_bench', 'id' => 'bad', 'pool' => 'dev', 'role' => nil },
                        { 'cell' => 'comparator.by_debate', 'id' => 'pair', 'pool' => 'dev', 'role' => nil }
                      ])
  end
end

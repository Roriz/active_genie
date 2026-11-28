# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../lib/active_genie/eval'

# ActiveGenie::Eval end to end inside a throwaway app: scaffold -> define -> run -> report -> baseline
# -> regression verdict, plus graders, the judge cache, labeling and the free check. No model is called.
class AppEvalTest < Minitest::Test
  Eval = ActiveGenie::Eval

  # Stands in for the judge model and counts its calls.
  class FakeAnswerer
    attr_reader :calls

    def initialize(answers)
      @answers = answers
      @calls = 0
    end

    def call(kind, _payload)
      @calls += 1
      @answers.fetch(kind)
    end
  end

  def setup
    @app = Dir.mktmpdir
    Eval.reset!
    Eval.app_root = @app
    @io = StringIO.new
    Eval::Scaffold.install(io: @io)
    File.write(File.join(@app, 'router.rb'), 'v1')
    @answers = { 'refund me' => { 'intent' => 'refund' }, 'where is it' => { 'intent' => 'delivery' } }
  end

  def teardown
    Eval.app_root = nil
    Eval.reset!
    Eval::Judge.online = false
    FileUtils.rm_rf(@app)
  end

  def test_scaffold_writes_the_starting_files_and_never_overwrites
    Eval::Scaffold.new_eval('ticket_router', io: @io)
    eval_rb = File.join(@app, 'evals', 'ticket_router', 'eval.rb')
    File.write(eval_rb, '# mine')
    Eval::Scaffold.new_eval('ticket_router', io: @io)

    assert_equal '# mine', File.read(eval_rb)
    %w[config.yml README.md .gitignore ticket_router/datasets.jsonl].each do |file|
      assert_path_exists File.join(@app, 'evals', file)
    end
    assert_match(%r{exists  evals/ticket_router/eval.rb}, @io.string)
    assert_raises(Eval::Error) { Eval::Scaffold.new_eval('Ticket Router', io: @io) }
  end

  def test_the_scaffolded_eval_passes_the_check_once_it_calls_something
    Eval::Scaffold.new_eval('ticket_router', io: @io)
    check = Eval::Check.new.run

    assert_predicate check, :ok?, check.report
  end

  def test_an_eval_is_named_after_its_folder
    write_eval('router', <<~RUBY)
      ActiveGenie::Eval.define('other') { call { |input| input } }
    RUBY

    assert_raises(Eval::EvalNameMismatchError) { Eval.load! }
  end

  def test_run_report_baseline_and_a_canary_regression
    define_router
    items = Eval::Selection.call(router, 'quick')

    assert_equal 2, items.size, 'quick runs the dev pool'
    assert_match(/MISSING 2 of 2 cases/, board(items).report)

    run_cases(items)

    assert_empty runner(items).pending, 'records are cached'
    assert_equal 'NO BASELINE', board(items).verdict

    full = Eval::Selection.call(router, 'full')
    run_cases(full)
    Eval::Baseline.save!(system, full, saved_by: 'test', force: true)
    File.write(File.join(@app, 'router.rb'), 'v2') # a watched file changed: a fresh run
    @answers['refund me'] = { 'intent' => 'delivery' }
    run_cases(items)
    report = board(items).report

    assert_equal 'STOP', board(items).verdict
    assert_match(/BROKE   refund_me \(canary\)/, report)
    assert_match(/delta vs baseline: -50\.0 pp/, report)
  end

  def test_the_summary_row_gives_the_field_rate_next_to_the_all_or_nothing_case_rate
    define_router
    gold = lambda do |intent|
      { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => intent },
                      'order_id' => { 'present' => false } } }
    end
    write_dataset('router', [
                    { 'id' => 'refund_me', 'pool' => 'dev', 'input' => { 'text' => 'refund me' }, 'gold' => gold.call('refund') },
                    { 'id' => 'where_is_it', 'pool' => 'dev', 'input' => { 'text' => 'where is it' }, 'gold' => gold.call('refund') }
                  ])
    items = Eval::Selection.call(router, 'quick')
    run_cases(items)

    row = board(items).summary_rows.first

    assert_in_delta 0.5, row[:rate], 1e-9, 'where_is_it fails as a case on one wrong field'
    assert_in_delta 0.75, row[:fields], 1e-9, 'three of its four fields are right'
  end

  def test_the_call_block_gets_a_context_and_results_keep_their_reasoning
    seen = []
    define_router(call: lambda do |input, context|
      seen << [context.provider, context.model, context.row['id']]
      ActiveGenie::Result.new(data: @answers.fetch(input['text']), reasoning: 'because', metadata: { tokens: 3 })
    end)
    items = Eval::Selection.call(router, 'quick')
    model = ActiveGenie.configuration.llm.model
    begin
      runner(items, provider: nil, model: 'm1').run!(judge: false)
    ensure
      ActiveGenie.configuration.llm.model = model # the run points ActiveGenie at its model
    end
    record = JSON.parse(File.read(runner(items, provider: nil, model: 'm1').record_path(items.first)))

    assert_equal [nil, 'm1', 'refund_me'], seen.min_by(&:last)
    assert_equal 'because', record['output']['reasoning']
    assert_equal({ 'tokens' => 3 }, record['output']['metadata'])
  end

  def test_a_failing_case_is_recorded_and_retried
    define_router(call: ->(_input) { raise 'provider down' })
    items = Eval::Selection.call(router, 'quick')
    runner(items).run!(judge: false)

    assert_equal 2, runner(items).pending.size
    assert_match(/ERROR\s+refund_me: RuntimeError: provider down/, board(items).report)
  end

  def test_rubric_rows_are_judged_once_and_cached
    write_eval('reply', <<~RUBY)
      ActiveGenie::Eval.define('reply') do
        call { |input| "Sorry about \#{input['text']}" }
        grader :rubric
        watch 'router.rb'
      end
    RUBY
    write_dataset('reply', [{ 'id' => 'late', 'pool' => 'dev', 'input' => { 'text' => 'the delay' },
                              'gold' => { 'rubric' => 'Apologizes', 'band' => [70, 100] } }])
    answerer = FakeAnswerer.new('rubric' => { 'score' => 80, 'reason' => 'polite' })
    Eval::Judge.current = Eval::Judge.new(provider: 'fake', model: 'fake-judge', answerer:)
    definition = Eval.fetch('reply')
    items = Eval::Selection.call(definition, 'quick')
    sys = Eval::System.new(definition:, provider: nil, model: nil)
    Eval::Runner.new(system: sys, items:, io: @io).run!(judge: false)

    assert_equal 'unjudged', Eval::Results.load(definition, sys.run_root, items).rows.first.grade.detail['outcome']

    Eval::Runner.new(system: sys, items:, io: @io).run!(judge: true)
    Eval::Judge.current = Eval::Judge.new(provider: 'fake', model: 'fake-judge', answerer:)
    grade = Eval::Results.load(definition, sys.run_root, items).rows.first.grade

    assert grade.pass
    assert_in_delta 80.0, grade.detail['score']
    assert_equal 1, answerer.calls, 'the verdict is read back from evals/judge/'
  end

  # Every case used to fail on its own call with AG-E007. Now the run stops once, before it asks to spend.
  def test_a_run_pinned_to_a_provider_without_a_key_stops_before_the_question
    define_router(call: ->(_input) { flunk 'the feature was called' })
    require 'rake'
    load File.expand_path('../../../lib/tasks/eval.rake', __dir__)
    previous = ENV.fetch('EVAL', nil)
    ENV['EVAL'] = 'router' # evals/config.yml pins the run to openai, which has no key here

    error = nil
    ActiveGenieEvalTasks.stub(:confirmed?, ->(_runners) { flunk 'it asked to spend' }) do
      capture_io { error = assert_raises(ActiveGenie::ProviderWithoutApiKeyError) { ActiveGenieEvalTasks.run('quick') } }
    end

    assert_includes error.message, 'The default provider "openai" has no API key'
    refute_path_exists Eval::System.from_env(router).run_root, 'nothing ran'
  ensure
    ENV['EVAL'] = previous
  end

  def test_a_run_whose_judge_provider_has_no_key_raises_before_any_case_runs
    write_eval('reply', <<~RUBY)
      ActiveGenie::Eval.define('reply') do
        call { |input| "Sorry about \#{input['text']}" }
        grader :rubric
        watch 'router.rb'
      end
    RUBY
    write_dataset('reply', [{ 'id' => 'late', 'pool' => 'dev', 'input' => { 'text' => 'the delay' },
                              'gold' => { 'rubric' => 'Apologizes', 'band' => [70, 100] } }])
    definition = Eval.fetch('reply')
    runner = Eval::Runner.new(system: Eval::System.new(definition:, provider: nil, model: nil),
                              items: Eval::Selection.call(definition, 'quick'), io: @io)

    error = assert_raises(ActiveGenie::ProviderWithoutApiKeyError) { runner.run!(judge: true) }

    assert_includes error.message, 'The default provider "anthropic" has no API key' # the judge's, from config.yml
    assert_equal 1, runner.pending.size, 'no case ran'

    runner.run!(judge: false) # a run that won't call the judge doesn't need its key

    assert_empty runner.pending
  end

  def test_a_malformed_judge_answer_is_not_cached
    Eval::Judge.current = Eval::Judge.new(provider: 'fake', model: 'fake-judge',
                                          answerer: FakeAnswerer.new('equivalence' => { 'match' => 'yes' }))
    Eval::Judge.online = true
    spec = { 'present' => true, 'check' => 'eq', 'value' => 'refund', 'judge' => true, 'question' => 'What is asked?' }

    assert_raises(Eval::MalformedJudgeAnswerError) { Eval::Graders::Fields.outcome(spec, 'money back') }
    refute_path_exists File.join(@app, 'evals', 'judge', 'fake-judge.jsonl')
  end

  def test_graders
    fields = { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => 'refund' },
                             'order' => { 'present' => false } } }

    assert_equal({ 'intent' => 'correct', 'order' => 'invention' },
                 Eval::Graders::Fields.grade(fields, { 'intent' => 'Refund', 'order' => '12' }).detail['fields'])
    assert Eval::Graders::Fields.grade({ 'fields' => { 'value' => { 'present' => true, 'check' => 'gte', 'value' => 3 } } }, 4).pass
    assert Eval::Graders::Band.grade({ 'band' => [60, 100] }, { 'score' => 75 }).pass
    refute Eval::Graders::Band.grade({ 'band' => [60, 100] }, 'about fifty').pass
    assert Eval::Graders::List.grade({ 'checks' => [{ 'type' => 'top_k_any', 'k' => 1, 'any_of' => ['apple'] }] }, %w[Apples]).pass
  end

  def test_a_custom_grader_returns_a_pass_and_details
    define_router(grader: ->(output, gold, _record) { { pass: output['intent'] == gold['intent'], 'got' => output['intent'] } })
    write_dataset('router', [{ 'id' => 'refund_me', 'pool' => 'dev', 'input' => { 'text' => 'refund me' }, 'gold' => { 'intent' => 'refund' } }])
    items = Eval::Selection.call(router, 'quick')
    run_cases(items)
    grade = Eval::Results.load(router, system.run_root, items).rows.first.grade

    assert grade.pass
    assert_equal({ 'got' => 'refund' }, grade.detail)
  end

  def test_labeling_waits_for_both_passes_and_never_touches_human_statuses
    define_router
    gold = { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => 'refund' } } }
    row = ->(id, status) { { 'id' => id, 'pool' => 'test', 'status' => status, 'input' => { 'text' => id }, 'gold' => gold }.compact }
    write_dataset('router', [row.call('agreed', 'draft'), row.call('split', 'draft'), row.call('half', 'draft'),
                             row.call('settled', 'decided'), row.call('plain', nil)])
    label = ->(id, pass, intent) { { 'id' => id, 'pass' => pass, 'values' => { 'intent' => intent } } }
    Eval::Store.write_jsonl(File.join(@app, 'evals', 'router', 'gold.jsonl'), [
                              label.call('agreed', 'a', 'Refund'), label.call('agreed', 'b', 'refund'),
                              label.call('split', 'a', 'refund'), label.call('split', 'b', 'billing'),
                              label.call('half', 'a', 'refund'), label.call('settled', 'a', 'billing'),
                              label.call('settled', 'b', 'billing'), label.call('plain', 'a', 'billing')
                            ])

    assert_equal([{ 'id' => 'agreed', 'input' => { 'text' => 'agreed' }, 'fields' => ['intent'] }],
                 Eval::Labeling.blind(router).first(1))

    result = Eval::Labeling.merge(router)

    assert_equal [1, 1, 1], result.values_at(:confirmed, :queued, :draft)
    assert_equal(%w[confirmed queued draft decided] + [nil], Eval::Store.rows(router).map { |r| r['status'] })
    assert_equal(%w[agreed settled plain], Eval::Store.cases(router).map { |r| r['id'] })
  end

  def test_check_finds_broken_data
    define_router
    write_dataset('router', [
                    { 'id' => 'ok', 'pool' => 'dev', 'input' => {}, 'gold' => { 'fields' => { 'a' => { 'present' => false } } } },
                    { 'id' => 'typo', 'pool' => 'dev', 'input' => {}, 'gold' => { 'fields' => { 'a' => { 'present' => true, 'check' => 'equals' } } } },
                    { 'id' => 'odd_status', 'pool' => 'dev', 'status' => 'exclude', 'input' => {}, 'gold' => { 'fields' => { 'a' => { 'present' => false } } } },
                    { 'id' => 'no_pool', 'input' => {}, 'gold' => { 'fields' => { 'a' => { 'present' => false } } } },
                    { 'id' => 'ok', 'pool' => 'dev', 'input' => {}, 'gold' => { 'fields' => { 'a' => { 'present' => false } } } }
                  ])
    Eval::Store.write_jsonl(File.join(@app, 'evals', 'router', 'gold.jsonl'), [{ 'id' => 'gone', 'pass' => 'a' }])

    check = Eval::Check.new.run
    errors = check.errors.join("\n")

    refute_predicate check, :ok?
    assert_match %r{router/typo: unknown or missing check for a}, errors
    assert_match %r{router/odd_status: status must be one of}, errors
    assert_match %r{router/no_pool: pool must be dev or test}, errors
    assert_match %r{router/ok: id appears 2 times in datasets.jsonl}, errors
    assert_match %r{router/gold.jsonl: gone is not a row of datasets.jsonl}, errors
    refute_includes Eval::Store.cases(router).map { |r| r['id'] }, 'odd_status', 'a status typo keeps the row out'
  end

  def test_check_rejects_a_list_count_no_output_can_meet
    write_eval('lister', "ActiveGenie::Eval.define('lister') { call { |i| [] }\n grader :list\n watch 'router.rb' }\n")
    count = ->(min, max) { { 'checks' => [{ 'type' => 'min_items', 'n' => min }, { 'type' => 'max_items', 'n' => max }] } }
    write_dataset('lister', [{ 'id' => 'exactly_three', 'pool' => 'dev', 'input' => {}, 'gold' => count.call(3, 3) },
                             { 'id' => 'never', 'pool' => 'dev', 'input' => {}, 'gold' => count.call(4, 3) },
                             { 'id' => 'zero', 'pool' => 'dev', 'input' => {}, 'gold' => count.call(1, 0) }])
    errors = Eval::Check.new.run.errors.join("\n")

    refute_match %r{lister/exactly_three}, errors
    assert_match %r{lister/never: min_items 4 is more than max_items 3}, errors
    assert_match %r{lister/zero: max_items needs a well-formed n}, errors
  end

  def test_a_call_block_raising_a_script_error_is_recorded_not_a_crash
    define_router(call: ->(_input) { raise NotImplementedError, 'call your feature' })
    items = Eval::Selection.call(router, 'quick')
    runner(items).run!(judge: false)

    assert_match(/ERROR\s+refund_me: NotImplementedError: call your feature/, board(items).report)
  end

  def test_a_case_missing_from_a_replicate_is_not_a_flip
    define_router(call: ->(_input) { { 'intent' => 'wrong' } })
    items = Eval::Selection.call(router, 'quick')
    Eval::Runner.new(system:, items:, replicate: 1, io: @io).run!(judge: false)
    Eval::Runner.new(system:, items: items.first(1), replicate: 2, io: @io).run!(judge: false)

    assert_match(/noise floor: 0\.0% of 1 cases flip/, board(items).report)
  end

  def test_an_unjudged_label_is_queued_not_dropped
    define_router
    spec = { 'present' => true, 'check' => 'eq', 'value' => 'refund', 'judge' => true, 'question' => 'What?' }
    write_dataset('router', [{ 'id' => 'x', 'pool' => 'dev', 'status' => 'draft', 'on_disagreement' => 'drop',
                               'input' => {}, 'gold' => { 'fields' => { 'intent' => spec } } }])
    Eval::Store.write_jsonl(File.join(@app, 'evals', 'router', 'gold.jsonl'),
                            [{ 'id' => 'x', 'pass' => 'a', 'values' => { 'intent' => 'money back' } },
                             { 'id' => 'x', 'pass' => 'b', 'values' => { 'intent' => 'refund' } }])

    assert_equal 1, Eval::Labeling.merge(router)[:queued]
  end

  def test_check_catches_values_the_matchers_cannot_use_and_a_missing_judge
    define_router
    spec = ->(check, value, **rest) { { 'present' => true, 'check' => check, 'value' => value }.merge(rest.transform_keys(&:to_s)) }
    write_dataset('router', [{ 'id' => 'bad', 'pool' => 'dev', 'input' => {},
                               'gold' => { 'fields' => { 'a' => spec.call('between', 5), 'b' => spec.call('near', 5),
                                                         'c' => spec.call('regex', '('), 'd' => spec.call('gte', '3'),
                                                         'e' => spec.call('eq', 'x', judge: true, question: 'Q?') } } }])
    File.write(File.join(@app, 'evals', 'config.yml'), "dev:\n  model: m\nusd_per_million_tokens:\n")
    Eval.reset!
    errors = Eval::Check.new.run.errors.join("\n")

    ['a: between', 'b: near', 'c: regex', 'd: gte'].each { |field| assert_includes errors, field }
    assert_match %r{grades with the judge, but evals/config.yml has no judge}, errors
    assert_match(/no eval nope in evals/, Eval::Check.new.run(only: 'nope').errors.join)
    assert_nil runner([]).estimate['usd'], 'a price list left empty reads as no price'
  end

  private

  def router = Eval.fetch('router')

  def system(provider: nil, model: nil) = Eval::System.new(definition: router, provider:, model:)

  def runner(items, provider: nil, model: nil)
    Eval::Runner.new(system: system(provider:, model:), items:, concurrency: 2, io: @io)
  end

  def run_cases(items) = runner(items).run!(judge: false)

  def board(items) = Eval::Scoreboard.new(system:, items:, mode: 'quick')

  # The router eval, with `call` and `grader` stubbed from the test.
  def define_router(call: ->(input) { @answers.fetch(input['text']) }, grader: :fields)
    write_eval('router', <<~RUBY)
      ActiveGenie::Eval.define('router') do
        call { |input, context| AppEvalTest.current_call.arity == 1 ? AppEvalTest.current_call.call(input) : AppEvalTest.current_call.call(input, context) }
        watch 'router.rb'
      end
    RUBY
    self.class.current_call = call
    router.grader = grader.is_a?(Symbol) ? grader.to_s : grader
    gold = ->(intent) { { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => intent } } } }
    write_dataset('router', [
                    { 'id' => 'refund_me', 'pool' => 'dev', 'input' => { 'text' => 'refund me' }, 'gold' => gold.call('refund') },
                    { 'id' => 'where_is_it', 'pool' => 'dev', 'input' => { 'text' => 'where is it' }, 'gold' => gold.call('delivery') },
                    { 'id' => 'held_out', 'pool' => 'test', 'input' => { 'text' => 'refund me' }, 'gold' => gold.call('refund') }
                  ])
  end

  class << self
    attr_accessor :current_call
  end

  def write_eval(name, source)
    file = File.join(@app, 'evals', name, 'eval.rb')
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, source)
    Eval.reset!
    Eval.app_root = @app
  end

  def write_dataset(name, rows)
    Eval::Store.write_jsonl(File.join(@app, 'evals', name, 'datasets.jsonl'), rows)
  end
end

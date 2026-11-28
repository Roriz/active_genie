# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../lib/active_genie/eval'

# Variants (several subjects on the same cases, compared head to head), twin rows (an input and the
# same input with one change, run with a shared context), the winner grader's labeling, and the
# config-level watch.
class AppEvalVariantsTwinsTest < Minitest::Test
  Eval = ActiveGenie::Eval

  def setup
    @app = Dir.mktmpdir
    Eval.reset!
    Eval.app_root = @app
    Eval::Scaffold.install(io: StringIO.new)
    File.write(File.join(@app, 'picker.rb'), 'v1')
    @io = StringIO.new
  end

  def teardown
    Eval.app_root = nil
    Eval.reset!
    FileUtils.rm_rf(@app)
  end

  def test_variants_run_the_same_cases_and_compare_head_to_head
    write_eval('picker', <<~RUBY, [row('one', 'a'), row('two', 'a'), row('three', 'b')])
      ActiveGenie::Eval.define('picker') do
        variant(:always_a) { |_input| { 'ab' => 'a', 'ba' => 'a' } }
        variant(:smart) { |input, context| side = input['answer']; { 'ab' => side, 'ba' => context.variant == 'smart' ? side : nil } }
        grader :winner
        watch 'picker.rb'
      end
    RUBY
    definition = Eval.fetch('picker')
    items = Eval::Selection.call(definition, 'full')

    assert_equal %w[always_a/one always_a/three always_a/two smart/one smart/three smart/two], items.map(&:key).sort
    board = run_and_report(definition, items)
    report = board.report

    assert_match(/^  always_a\s+3\s+2\s+66\.7%/, report)
    assert_match(/^  smart\s+3\s+3\s+100\.0%/, report)
    assert_match(%r{always_a vs smart on 3 shared cases: \+0 / -1, McNemar p=1\.000}, report)
    assert_match(/Winner · smart/, report, 'each variant gets its own matrices')
    assert_equal([['picker/always_a', 3, 2.0 / 3], ['picker/smart', 3, 1.0]],
                 board.summary_rows.map { |r| [r[:name], r[:cases], r[:rate]] })
    runner = Eval::Runner.new(system: Eval::System.new(definition:, provider: nil, model: nil), items:, io: @io)

    assert_equal 6, runner.send(:history).size, 'the estimate learns from the records in each variant folder'
  end

  def test_a_twin_row_runs_twice_with_a_shared_context
    seen = []
    write_eval('scorer', <<~RUBY, [twin_row])
      ActiveGenie::Eval.define('scorer') do
        call do |input, context|
          context.shared[:picked] ||= "juries for \#{input['text']}"
          AppEvalVariantsTwinsTest.seen << [input['text'], context.twin, context.shared[:picked]]
          input['text'].size * 10
        end
        grader :band
        watch 'picker.rb'
      end
    RUBY
    self.class.seen = seen
    definition = Eval.fetch('scorer')
    items = Eval::Selection.call(definition, 'full')
    board = run_and_report(definition, items)

    assert_equal [['plain', false, 'juries for plain'], ['plain!!', true, 'juries for plain']], seen
    assert_match(/Twin pairs/, board.report)
    assert_match(/^  verbosity\s+1\s+\+20\.0\s+20\.0\s+0$/, board.report, 'a gap of 20 is over the max_gap of 10')
  end

  def test_labeling_winner_and_twin_rows
    write_eval('picker', "ActiveGenie::Eval.define('picker') { call { |i| i }\n grader :winner\n watch 'picker.rb' }\n",
               [row('one', 'a', status: 'draft'), row('two', 'b', status: 'draft')])
    label = ->(id, pass, winner) { { 'id' => id, 'pass' => pass, 'values' => { 'winner' => winner } } }
    Eval::Store.write_jsonl(File.join(@app, 'evals', 'picker', 'gold.jsonl'),
                            [label.call('one', 'a', 'a'), label.call('one', 'b', 'a'),
                             label.call('two', 'a', 'b'), label.call('two', 'b', 'a')])

    assert_equal [1, 1], Eval::Labeling.merge(Eval.fetch('picker')).values_at(:confirmed, :queued)

    Eval::Store.write_jsonl(File.join(@app, 'evals', 'picker', 'gold.jsonl'), [label.call('one', 'a', 'A')])
    assert_raises(Eval::InvalidWinnerLabelError, 'a broken label is not a silent disagreement') do
      Eval::Labeling.merge(Eval.fetch('picker'))
    end

    band = Eval::Definition.new(name: 'b', dir: @app).tap { |d| d.grader = 'band' }
    spec = { 'band' => [40, 80], 'max_gap' => 10 }

    assert Eval::Labeling.accepts?(band, spec, { 'text' => 60, 'twin' => 65 })
    refute Eval::Labeling.accepts?(band, spec, { 'text' => 50, 'twin' => 75 })
    refute Eval::Labeling.accepts?(band, { 'band' => [40, 80] }, { 'text' => 60, 'twin' => 95 }, twin: true),
           'without max_gap a twin row still needs both scores in the band, as the grader does'
  end

  def test_a_blind_labeler_sees_the_twin_and_a_pending_twin_verdict_is_unjudged
    write_eval('scorer', "ActiveGenie::Eval.define('scorer') { call { |i| 1 }\n grader :band\n watch 'picker.rb' }\n",
               [twin_row.merge('status' => 'draft')])

    assert_equal [{ 'id' => 'wordy', 'input' => { 'text' => 'plain' }, 'twin' => { 'text' => 'plain!!' },
                    'fields' => ['score'] }], Eval::Labeling.blind(Eval.fetch('scorer'))
    assert_predicate Eval::Graders::Grade.new(pass: false, detail: { 'score' => 50, 'twin' => { 'outcome' => 'unjudged' } }),
                     :unjudged?
  end

  def test_check_validates_twins_and_winners
    rows = [{ 'id' => 'no_twin', 'pool' => 'dev', 'input' => { 'text' => 't' }, 'gold' => { 'band' => [0, 100], 'max_gap' => 5 } },
            { 'id' => 'same', 'pool' => 'dev', 'input' => { 'text' => 't' }, 'twin' => { 'text' => 't' }, 'gold' => { 'band' => [0, 100] } },
            { 'id' => 'string', 'pool' => 'dev', 'input' => { 'text' => 't' }, 'twin' => 'x', 'gold' => { 'band' => [0, 100] } },
            { 'id' => 'text_input', 'pool' => 'dev', 'input' => 't', 'twin' => { 'text' => 'u' }, 'gold' => { 'band' => [0, 100] } }]
    write_eval('scorer', "ActiveGenie::Eval.define('scorer') { call { |i| 1 }\n grader :band\n watch 'picker.rb' }\n", rows)
    write_eval('picker', "ActiveGenie::Eval.define('picker') { call { |i| i }\n grader :winner\n watch 'picker.rb' }\n",
               [row('bad', 'c')])
    errors = Eval::Check.new.run.errors.join("\n")

    assert_match %r{scorer/no_twin: max_gap needs a twin}, errors
    assert_match %r{scorer/same: twin must change the input}, errors
    assert_match %r{scorer/string: twin must be an object}, errors
    assert_match %r{scorer/text_input: a twin needs an object input}, errors
    assert_match %r{picker/bad: winner must be one of a, b, either}, errors
  end

  def test_config_watch_is_the_default_for_every_eval
    File.write(Eval.path('config.yml'), "watch:\n  - picker.rb\n")
    write_eval('picker', "ActiveGenie::Eval.define('picker') { call { |i| i } }\n", [])

    assert_equal ['evals/picker/eval.rb', 'picker.rb'], Eval.fetch('picker').watched_files
  end

  class << self
    attr_accessor :seen
  end

  private

  def row(id, winner, status: nil)
    { 'id' => id, 'pool' => 'test', 'status' => status, 'input' => { 'answer' => winner },
      'gold' => { 'winner' => winner } }.compact
  end

  def twin_row
    { 'id' => 'wordy', 'pool' => 'dev', 'tags' => { 'bias' => 'verbosity' }, 'input' => { 'text' => 'plain' },
      'twin' => { 'text' => 'plain!!' }, 'gold' => { 'band' => [0, 100], 'max_gap' => 10 } }
  end

  def write_eval(name, source, rows)
    dir = File.join(@app, 'evals', name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'eval.rb'), source)
    Eval::Store.write_jsonl(File.join(dir, 'datasets.jsonl'), rows)
    Eval.reset!
    Eval.app_root = @app
  end

  def run_and_report(definition, items)
    system = Eval::System.new(definition:, provider: nil, model: nil)
    Eval::Runner.new(system:, items:, io: @io).run!(judge: false)
    Eval::Scoreboard.new(system:, items:, mode: 'full')
  end
end

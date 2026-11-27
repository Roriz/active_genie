# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../lib/active_genie/eval'

# The parts of a run you read: the overview and plan before it, the progress line during it, and the
# report's confusion matrices after it, in text and markdown.
class AppEvalReportTest < Minitest::Test
  Eval = ActiveGenie::Eval
  Row = Eval::Results::Row
  Grade = Eval::Graders::Grade

  def setup
    @app = Dir.mktmpdir
    Eval.reset!
    Eval.app_root = @app
    Eval::Scaffold.install(io: StringIO.new)
    File.write(File.join(@app, 'router.rb'), 'v1')
  end

  def teardown
    Eval.app_root = nil
    Eval.reset!
    FileUtils.rm_rf(@app)
  end

  def test_report_renders_the_same_blocks_as_text_and_markdown
    report = Eval::Report.new.heading('Results').table(%w[eval cases rate], [['router', 12, '75.0%']]).line('done')

    assert_equal "Results\n  eval    cases   rate\n  router     12  75.0%\ndone", report.to_text, 'number columns right-align'
    assert_equal "### Results\n\n| eval | cases | rate |\n| :-- | --: | --: |\n| router | 12 | 75.0% |\n\ndone\n",
                 report.to_markdown
  end

  def test_categorical_matrix_counts_gold_against_predicted
    rows = [cell('refund', 'refund', 'correct'), cell('refund', 'refund', 'correct'), cell('billing', 'refund', 'wrong_value'),
            cell('billing', 'billing', 'correct'), cell(nil, 'refund', 'invention')]
    text = Eval::Matrices.categorical(rows).to_text

    assert_match(/intent: gold ↓ · predicted →/, text)
    assert_match(/^\s+billing\s+refund\s+\(none\)$/, text, 'ties sort by label')
    assert_match(/^  billing\s+1\s+1\s+·$/, text)
    assert_match(/^  refund\s+·\s+2\s+·$/, text)
    assert_match(/^  \(none\)\s+·\s+1\s+·$/, text, 'an absent gold is a row of its own')
    assert_match(%r{accuracy 60% \(3/5\) · most confused: \(none\) → refund \(1\), billing → refund \(1\)}, text)
  end

  def test_long_labels_stay_on_the_diagonal_and_the_overflow_column_never_collides_with_other
    long = 'account_access_and_security_issue'
    text = Eval::Matrices.categorical([cell(long, long, 'correct'), cell(long, long, 'correct'),
                                       cell('billing', 'billing', 'correct')]).to_text

    assert_match(/^  account_access_and_security_is\s+2\s+·$/, text, 'gold and predicted are cut the same way')

    rows = %w[a b c d e f g other x y].flat_map { |label| [cell(label, label, 'correct')] * 2 }
    text = Eval::Matrices.categorical(rows).to_text

    assert_match(/^\s+a\s+b\s+c\s+d\s+e\s+f\s+g\s+other\s+\(other\)$/, text)
    assert_match(/^  x\s+(?:·\s+){8}2$/, text, 'the long tail goes to (other), not to the "other" category')
  end

  def test_a_field_with_a_gold_that_is_not_a_label_is_not_a_category
    rows = [cell('refund', 'refund', 'correct'), cell('refund', 'refund', 'correct'), cell('billing', 'billing', 'correct'),
            row({ 'fields' => { 'intent' => 'correct' } }, data: { 'intent' => 'refund' },
                                                           gold: { 'fields' => { 'intent' => { 'present' => true, 'check' => 'regex', 'value' => 'ref' } } })]

    assert_empty Eval::Matrices.categorical(rows).blocks
  end

  def test_custom_grader_details_are_not_read_as_matrices
    custom = [row({ 'band' => 'premium', 'score' => 3, 'fields' => %w[name email] })]

    assert_empty Eval::Matrices.bands(custom).blocks
    assert_empty Eval::Matrices.field_outcomes(custom).blocks
    assert_empty Eval::Matrices.categorical(custom).blocks
    refute_predicate custom.first.grade, :unjudged?
  end

  def test_ids_are_not_categories
    rows = %w[1001 1002 1003].map { |id| cell(id, id, 'correct') }

    assert_empty Eval::Matrices.categorical(rows).blocks
    refute Eval::Matrices.categorical?(%w[a b c])
    assert Eval::Matrices.categorical?(['a', 'a', 'b', Eval::Matrices::NONE])
  end

  def test_field_outcomes_baseline_and_band_matrices
    outcomes = [row({ 'fields' => { 'intent' => 'correct', 'order' => 'invention' } }),
                row({ 'fields' => { 'intent' => 'omission', 'order' => 'correct_abstention' } })]
    text = Eval::Matrices.field_outcomes(outcomes).to_text

    assert_match(/gold present\s+1 correct · 0 wrong\s+1 omission/, text)
    assert_match(/gold absent\s+1 invention\s+1 correct abstention/, text)

    now = [row({}, pass: false), row({}, pass: true), row({}, pass: true)]
    base = [row({}, pass: true), row({}, pass: false), row({}, pass: true)]

    assert_match(/baseline pass\s+1\s+1 broke\n\s+baseline fail\s+1 fixed\s+0/, Eval::Matrices.baseline(now.zip(base)).to_text)

    bands = [row({ 'score' => 30, 'band' => [60, 100] }), row({ 'score' => 70, 'band' => [60, 100] }),
             row({ 'score' => nil, 'band' => [60, 100] })]

    assert_match(/\[60, 100\]\s+1\s+1\s+·\s+1/, Eval::Matrices.bands(bands).to_text)
  end

  def test_overview_shows_size_diversity_and_the_plan
    define_router
    system = Eval::System.new(definition: Eval.fetch('router'), provider: 'openai', model: 'm1')
    runner = Eval::Runner.new(system:, items: Eval::Selection.call(system.definition, 'quick'), io: StringIO.new)
    overview = Eval::Overview.new(system:)
    text = overview.report.concat(overview.plan(mode: 'quick', runners: [runner])).to_text

    assert_match(/^  run\s+3\s+1\s+4$/, text)
    assert_match(/^  waiting for labels\s+0\s+1\s+1$/, text)
    assert_match(/difficulty\s+easy 3 · subtle 1/, text)
    assert_match(/field intent\s+2 values \(refund 3 · billing 1\)/, text)
    assert_match(/field order_id\s+present 4 · checks eq/, text, 'an id is not a category')
    assert_match(/quick: 3 dev cases, 0 cached, 3 to call/, text)
    assert_match(/~3 calls · ~12000 tokens · cost unknown .* · time unknown until a case has run/, text)
  end

  def test_overview_counts_false_tags_and_skips_tags_that_are_not_an_object
    define_router
    definition = Eval.fetch('router')
    rows = Eval::Store.rows(definition)
    rows[0]['tags'] = { 'difficulty' => 'easy', 'vip' => false }
    rows[1]['tags'] = %w[billing hard]
    rows[2]['tags'] = { 'difficulty' => 'subtle', 'vip' => true }
    Eval::Store.write_rows(definition, rows)
    text = Eval::Overview.new(system: Eval::System.new(definition:, provider: 'openai', model: 'm1')).report.to_text

    assert_match(/difficulty\s+easy 2 · subtle 1 · untagged 1/, text)
    assert_match(/tag vip\s+false 1 · true 1/, text)
  end

  def test_the_plan_counts_verdicts_waiting_in_every_replicate
    define_router(judge: true)
    system = Eval::System.new(definition: Eval.fetch('router'), provider: 'openai', model: 'm1')
    items = Eval::Selection.call(system.definition, 'quick').first(1)
    runners = [1, 2].map { |r| Eval::Runner.new(system:, items:, replicate: r, io: StringIO.new) }
    # r1 answered right; r2 failed the check, so its `judge: true` field waits for a verdict.
    { runners[0] => 'refund', runners[1] => 'a refund, please' }.each do |runner, intent|
      Eval::Store.write_json(runner.record_path(items.first),
                             { 'id' => items.first.id, 'input_sha' => items.first.input_sha,
                               'output' => { 'data' => { 'intent' => intent, 'order_id' => '1' } } })
    end

    assert_empty runners[0].unjudged
    assert_equal 1, runners[1].unjudged.size
    assert_match(/1 cached case\(s\) wait for a verdict/, Eval::Overview.new(system:).plan(mode: 'quick', runners:).to_text)
  end

  def test_progress_prints_one_line_per_tenth_off_a_terminal
    io = StringIO.new
    now = 0.0
    progress = Eval::Progress.new(total: 20, io:, clock: -> { now })
    20.times do |i|
      now += 1.5
      progress.tick(i == 3 ? { 'error' => 'x' } : {})
    end
    lines = io.string.lines

    assert_equal 11, lines.size, 'one line at each 10%, the first case included'
    assert_match(%r{\A\[█░{19}\] 1/20   5%  0:02 elapsed · ~0:29 left\n\z}, lines.first)
    assert_match(%r{\[█{20}\] 20/20 100%  0:30 elapsed · 1 error}, lines.last)
  end

  private

  def row(detail, pass: true, gold: {}, data: nil)
    item = Eval::Selection::Item.new(case: { 'id' => "c#{rand(1_000_000)}", 'gold' => gold })
    Row.new(item:, record: { 'output' => { 'data' => data } }, grade: Grade.new(pass:, detail:))
  end

  # One `intent` field: its gold (nil for absent), what came back, and the outcome.
  def cell(gold, predicted, outcome)
    spec = gold ? { 'present' => true, 'check' => 'eq', 'value' => gold } : { 'present' => false }
    row({ 'fields' => { 'intent' => outcome } }, gold: { 'fields' => { 'intent' => spec } }, data: { 'intent' => predicted })
  end

  def define_router(judge: false)
    dir = File.join(@app, 'evals', 'router')
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'eval.rb'), "ActiveGenie::Eval.define('router') { call { |i| i }\n watch 'router.rb' }\n")
    judged = judge ? { 'judge' => true, 'question' => 'What is asked?' } : {}
    gold = lambda do |intent, order|
      { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => intent }.merge(judged),
                      'order_id' => { 'present' => true, 'check' => 'eq', 'value' => order } } }
    end
    rows = [%w[a refund 1 dev easy], %w[b refund 2 dev easy], %w[c billing 3 dev subtle], %w[d refund 4 test easy]]
           .map { |id, intent, order, pool, diff| { 'id' => id, 'pool' => pool, 'tags' => { 'difficulty' => diff }, 'input' => {}, 'gold' => gold.call(intent, order) } }
    rows << { 'id' => 'e', 'pool' => 'test', 'status' => 'draft', 'input' => {}, 'gold' => gold.call('refund', '5') }
    Eval::Store.write_jsonl(File.join(dir, 'datasets.jsonl'), rows)
    Eval.reset!
    Eval.app_root = @app
  end
end

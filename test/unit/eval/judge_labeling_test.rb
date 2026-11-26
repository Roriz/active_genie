# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../eval/lib/genie_eval'

class GenieEvalJudgeLabelingTest < Minitest::Test
  Store = GenieEval::Store

  # Stands in for the judge model: answers from a table and counts calls.
  class FakeAnswerer
    attr_reader :calls

    def initialize(match)
      @match = match
      @calls = 0
    end

    def call(_instructions, _payload)
      @calls += 1
      { 'match' => @match, 'reason' => 'fake' }
    end
  end

  def setup
    @dir = Dir.mktmpdir
    GenieEval.root = @dir
    @answerer = FakeAnswerer.new(true)
    GenieEval::Judge.current = GenieEval::Judge.new(model: 'fake-judge', answerer: @answerer)
  end

  def teardown
    GenieEval::Judge.current = nil
    GenieEval::Judge.online = false
    GenieEval.root = nil
    FileUtils.rm_rf(@dir)
  end

  def renewal
    { 'present' => true, 'check' => 'eq', 'value' => 'successive 1 year', 'judge' => true,
      'question' => 'How does the agreement renew?' }
  end

  def test_date_check_reads_common_formats
    spec = { 'present' => true, 'check' => 'date', 'value' => '2014-02-10' }

    ['2/10/14', 'February 10th, 2014', '10 February 2014', '2014-02-10'].each do |written|
      assert GenieEval::Matchers.check?(spec, written), "#{written} should match"
    end
    refute GenieEval::Matchers.check?(spec, '2/11/14')
    assert GenieEval::Matchers.check?(spec, '2014-02-10T00:00:00Z')
    assert GenieEval::Matchers.check?(spec, 'February 10, 2014.')
    refute GenieEval::Matchers.check?(spec, '2014-02-10 or 2014-03-10'), 'a hedged second date is not the date'
  end

  def test_a_malformed_judge_answer_is_not_cached_as_a_verdict
    GenieEval::Judge.current = GenieEval::Judge.new(model: 'fake-judge', answerer: ->(_i, _p) { { 'match' => 'true' } })
    GenieEval::Judge.online = true

    assert_raises(GenieEval::Error) do
      GenieEval::Graders::Extractor.outcome(renewal, 'renews automatically for one-year periods')
    end
    assert_empty Store.read_jsonl(GenieEval.path('judge', 'fake-judge.jsonl'))
  end

  def test_labeling_refuses_an_unknown_set_cell_or_pass
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => 'extractor.data', 'grader' => 'extractor' }])
    gold = { 'fields' => { 'name' => { 'present' => true, 'check' => 'eq', 'value' => 'Ann' } } }

    assert_raises(GenieEval::Error) { GenieEval::Labeling.merge('extractor.dta') }

    write_set('extractor.data', [row('x', gold, cells: ['extractor.dta'])])

    assert_raises(GenieEval::Error) { GenieEval::Labeling.merge('extractor.data') }

    write_set('extractor.data', [row('x', gold, cells: ['extractor.data'])])
    Store.write_jsonl(GenieEval.path('labels', 'extractor.data.jsonl'), [{ 'id' => 'x', 'pass' => 'c', 'values' => {} }])

    assert_raises(GenieEval::Error) { GenieEval::Labeling.merge('extractor.data') }
  end

  def test_judge_is_offline_in_reports_and_cached_after_a_run
    outcome = -> { GenieEval::Graders::Extractor.outcome(renewal, 'renews automatically for one-year periods') }

    assert_equal 'unjudged', outcome.call, 'reports never call the judge'
    assert_equal 0, @answerer.calls

    GenieEval::Judge.online = true

    assert_equal 'correct', outcome.call
    GenieEval::Judge.online = false

    assert_equal 'correct', outcome.call, 'the verdict is read back from eval/judge/'
    assert_equal 1, @answerer.calls
    assert_equal 1, Store.read_jsonl(GenieEval.path('judge', 'fake-judge.jsonl')).size
  end

  def test_deterministic_match_skips_the_judge
    GenieEval::Judge.online = true

    assert_equal 'correct', GenieEval::Graders::Extractor.outcome(renewal, 'Successive 1 Year')
    assert_equal 0, @answerer.calls
  end

  def test_labeling_confirms_agreed_rows_and_queues_the_rest
    cell = 'extractor.with_litote'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'extractor', 'weight' => 1 }])
    gold = ->(value) { { 'fields' => { 'sentiment' => { 'present' => true, 'check' => 'eq', 'value' => value } } } }
    write_set(cell, [row('agreed', gold.call('positive')), row('split', gold.call('positive'))])
    write_labels(cell, a: { 'agreed' => { 'sentiment' => 'Positive' }, 'split' => { 'sentiment' => 'positive' } },
                       b: { 'agreed' => { 'sentiment' => 'Positive' }, 'split' => { 'sentiment' => 'neutral' } })

    result = GenieEval::Labeling.merge(cell)

    assert_equal [1, 1], result.values_at(:confirmed, :queued)
    assert_equal([%w[split sentiment]], result[:queue].map { |q| [q['id'], q['field']] })
    assert_equal(%w[agreed], Store.cases(cell).map { |c| c['id'] })
    assert_equal(%w[confirmed queued], Store.rows(cell).map { |r| r['status'] })

    settled = Store.rows(cell).map { |r| r['id'] == 'split' ? r.merge('gold' => gold.call('neutral'), 'status' => 'decided') : r }
    write_set(cell, settled)

    assert_equal [1, 0], GenieEval::Labeling.merge(cell).values_at(:confirmed, :queued)
    assert_equal 'decided', Store.rows(cell).last['status'], 'labeling never changes a human status'
    assert_equal(%w[agreed split], Store.cases(cell).map { |c| c['id'] })
  end

  def test_labeling_leaves_unlabeled_and_excluded_rows_alone
    cell = 'extractor.data'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'extractor', 'weight' => 1 }])
    gold = { 'fields' => { 'name' => { 'present' => true, 'check' => 'eq', 'value' => 'Ann' } } }
    write_set(cell, [row('migrated', gold, status: nil), row('out', gold, status: 'excluded'), row('fresh', gold)])
    write_labels(cell, a: %w[migrated out fresh].to_h { |id| [id, { 'name' => 'Bob' }] },
                       b: %w[migrated out fresh].to_h { |id| [id, { 'name' => 'Bob' }] })

    GenieEval::Labeling.merge(cell)

    assert_equal([nil, 'excluded', 'queued'], Store.rows(cell).map { |r| r['status'] })
    assert_equal(%w[migrated], Store.cases(cell).map { |c| c['id'] })
  end

  def test_blind_shows_drafts_without_their_gold
    cell = 'extractor.data'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'extractor', 'weight' => 1 }])
    gold = { 'fields' => { 'name' => { 'present' => true, 'check' => 'eq', 'value' => 'Ann' } } }
    write_set(cell, [row('new', gold), row('done', gold, status: 'confirmed')])

    assert_equal([{ 'id' => 'new', 'cells' => [cell], 'input' => { 'text' => 't' } }], GenieEval::Labeling.blind(cell))

    write_labels(cell, a: { 'done' => { 'name' => 'Ann' } }, b: { 'done' => { 'name' => 'Ann' } })

    assert_equal [1, 0, 1], GenieEval::Labeling.merge(cell).values_at(:confirmed, :queued, :draft)
    assert_equal(%w[new], GenieEval::Labeling.blind(cell).map { |r| r['id'] }, 'labeling before the passes keeps the draft')
    assert_raises(GenieEval::Error, 'a typo is not an empty set') { GenieEval::Labeling.blind('extractor.dta') }
  end

  def test_labeling_a_shared_set_feeds_each_cell_and_drops_unclear_pairs
    cells = %w[comparator.by_debate comparator.by_fight]
    Store.write_json(GenieEval.path('cells.json'), cells.map { |id| { 'id' => id, 'grader' => 'comparator', 'weight' => 1 } })
    input = { 'player_a' => 'x', 'player_b' => 'y', 'criteria' => 'c' }
    pair = ->(id, winner, drop: true) { row(id, { 'winner' => winner }, cells:, input:).merge(drop ? { 'on_disagreement' => 'drop' } : {}) }
    write_set('comparator', [pair.call('clear', 'a'), pair.call('noisy', 'b'), pair.call('half_bad', 'a'),
                             pair.call('half_good', 'a'), pair.call('mine', 'a', drop: false)])
    winner = ->(w) { { 'winner' => w } }
    write_labels('comparator',
                 a: { 'clear' => winner.call('a'), 'noisy' => winner.call('b'), 'half_bad' => winner.call('b'),
                      'half_good' => winner.call('a'), 'mine' => winner.call('b') },
                 b: { 'clear' => winner.call('a'), 'noisy' => winner.call('either'), 'mine' => winner.call('b') })

    result = GenieEval::Labeling.merge('comparator')

    assert_equal [1, 1, 2, 1], result.values_at(:confirmed, :queued, :dropped, :draft)
    assert_equal(%w[mine], result[:queue].map { |q| q['id'] }, 'rows without the flag go to a person')
    assert_equal(%w[half_good], GenieEval::Labeling.blind('comparator').map { |r| r['id'] },
                 'a missing pass waits, still shown to the blind labeler, while the other agrees')
    cells.each { |cell| assert_equal(%w[clear], Store.cases(cell).map { |c| c['id'] }) }

    write_labels('comparator', a: { 'clear' => winner.call('a') }, b: { 'clear' => winner.call('A') })
    assert_raises(GenieEval::Error, 'a broken label is not a silent drop') { GenieEval::Labeling.merge('comparator') }
  end

  def test_labeling_scores_a_bias_pair_from_both_texts
    cell = 'scorer.by_jury_bench'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'scorer', 'weight' => 1 }])
    input = { 'text' => 't', 'twin' => 't, says a professor', 'criteria' => 'c' }
    gold = { 'band' => [40, 80], 'max_gap' => 10 }
    write_set(cell, [row('close', gold, input:), row('apart', gold, input:)])
    score = ->(text, twin) { { 'score' => { 'text' => text, 'twin' => twin } } }
    write_labels(cell, a: { 'close' => score.call(60, 65), 'apart' => score.call(50, 52) },
                       b: { 'close' => score.call(60, 65), 'apart' => score.call(50, 75) })

    assert_equal [1, 1], GenieEval::Labeling.merge(cell).values_at(:confirmed, :queued)
  end

  def test_labeling_a_lister_case_checks_each_labelers_list
    cell = 'lister.with_feud'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'lister', 'weight' => 1 }])
    gold = { 'checks' => [{ 'type' => 'top_k_any', 'k' => 1, 'any_of' => ['apple'] },
                          { 'type' => 'no_item', 'any_of' => ['lychee'] }] }
    write_set(cell, [row('agreed', gold, input: { 'theme' => 't' }), row('split', gold, input: { 'theme' => 't' })])
    write_labels(cell, a: { 'agreed' => { 'list' => %w[Apples Cherry] }, 'split' => { 'list' => %w[Apple] } },
                       b: { 'agreed' => { 'list' => %w[Apples Cherry] }, 'split' => { 'list' => %w[Apple Lychee] } })

    assert_equal [1, 1], GenieEval::Labeling.merge(cell).values_at(:confirmed, :queued)
  end

  def test_a_lister_pass_must_give_a_list_of_answers
    cell = 'lister.with_feud'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'lister', 'weight' => 1 }])
    write_set(cell, [row('red', { 'checks' => [{ 'type' => 'no_item', 'any_of' => ['lychee'] }] }, input: { 'theme' => 't' })])
    label = ->(list) { write_labels(cell, a: { 'red' => { 'list' => list } }, b: { 'red' => { 'list' => list } }) }

    label.call(nil)

    assert_equal [0, 1], GenieEval::Labeling.merge(cell).values_at(:confirmed, :queued), 'no answers are not agreement'

    label.call('Apple, Cherry')

    assert_raises(GenieEval::Error, 'a string is a broken label') { GenieEval::Labeling.merge(cell) }
  end

  private

  # A drafted row; without `cells`, write_set puts it in the cell its set is named after.
  def row(id, gold, cells: nil, input: { 'text' => 't' }, status: 'draft')
    { 'id' => id, 'cells' => cells, 'pool' => 'test', 'status' => status, 'input' => input, 'gold' => gold }.compact
  end

  def write_set(set, rows)
    Store.write_rows(set, rows.map { |r| { 'cells' => [set] }.merge(r) })
  end

  # { id => values } for each pass.
  def write_labels(set, a:, b:) # rubocop:disable Naming/MethodParameterName -- the pass names
    rows = { 'a' => a, 'b' => b }.flat_map { |pass, by_id| by_id.map { |id, values| { 'id' => id, 'pass' => pass, 'values' => values } } }
    Store.write_jsonl(GenieEval.path('labels', "#{set}.jsonl"), rows)
  end
end

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

  def test_labeling_refuses_an_unknown_cell_or_field_action
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => 'extractor.data', 'grader' => 'extractor' }])

    assert_raises(GenieEval::Error) { GenieEval::Labeling.merge('extractor.dta') }
    refute_path_exists GenieEval.path('cases', 'extractor.dta.jsonl')

    Store.write_jsonl(GenieEval.path('labeling', 'extractor.data', 'decisions.jsonl'),
                      [{ 'id' => 'x', 'field' => 'f', 'action' => 'exclude' }])
    assert_raises(GenieEval::Error) { GenieEval::Labeling.latest_decisions('extractor.data') }
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

  def test_labeling_promotes_agreed_cases_and_queues_the_rest
    cell = 'extractor.with_litote'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'extractor', 'weight' => 1 }])
    draft = lambda do |id, value|
      { 'id' => id, 'cell' => cell, 'source' => 'drafted', 'tags' => {}, 'why' => 'w',
        'input' => { 'text' => 't', 'schema' => { 'sentiment' => { 'type' => 'string' } } },
        'gold' => { 'fields' => { 'sentiment' => { 'present' => true, 'check' => 'eq', 'value' => value } } } }
    end
    Store.write_jsonl(GenieEval.path('labeling', 'drafts', "#{cell}.jsonl"), [draft.call('agreed', 'positive'), draft.call('split', 'positive')])
    %w[a b].each do |pass|
      Store.write_jsonl(GenieEval.path('labeling', cell, "pass_#{pass}.jsonl"), [
                          { 'id' => 'agreed', 'values' => { 'sentiment' => 'Positive' } },
                          { 'id' => 'split', 'values' => { 'sentiment' => pass == 'a' ? 'positive' : 'neutral' } }
                        ])
    end

    result = GenieEval::Labeling.merge(cell)

    assert_equal 1, result[:promoted]
    assert_equal([%w[split sentiment]], result[:queue].map { |q| [q['id'], q['field']] })
    assert_equal(['agreed'], Store.cases(cell).map { |c| c['id'] })

    Store.write_jsonl(GenieEval.path('labeling', cell, 'decisions.jsonl'), [
                        { 'id' => 'split', 'field' => 'sentiment', 'action' => 'set',
                          'spec' => { 'present' => true, 'check' => 'eq', 'value' => 'neutral' } }
                      ])

    assert_equal 2, GenieEval::Labeling.merge(cell)[:promoted]
    assert_equal 'neutral', Store.gold(cell)['split']['gold']['fields']['sentiment']['value']
    assert_equal(%w[test test], Store.pools.map { |p| p['pool'] })
  end

  def test_labeling_a_shared_set_feeds_each_cell_and_drops_unclear_pairs
    cells = %w[comparator.by_debate comparator.by_fight]
    Store.write_json(GenieEval.path('cells.json'), cells.map { |id| { 'id' => id, 'grader' => 'comparator', 'weight' => 1 } })
    draft = lambda do |id, winner, extra = {}|
      { 'id' => id, 'cells' => cells, 'source' => 'hh-rlhf', 'tags' => {}, 'why' => 'w',
        'input' => { 'player_a' => 'x', 'player_b' => 'y', 'criteria' => 'c' },
        'gold' => { 'winner' => winner } }.merge(extra)
    end
    drop = { 'on_disagreement' => 'drop', 'labeled_by' => 'crowd' }
    Store.write_jsonl(GenieEval.path('labeling', 'drafts', 'comparator.jsonl'), [
                        draft.call('clear', 'a', drop),
                        draft.call('noisy', 'b', drop),
                        draft.call('half_bad', 'a', drop),
                        draft.call('half_good', 'a', drop),
                        draft.call('mine', 'a')
                      ])
    %w[a b].each do |pass|
      Store.write_jsonl(GenieEval.path('labeling', 'comparator', "pass_#{pass}.jsonl"), [
                          { 'id' => 'clear', 'values' => { 'winner' => 'a' } },
                          { 'id' => 'noisy', 'values' => { 'winner' => pass == 'a' ? 'b' : 'either' } },
                          *(pass == 'a' ? [{ 'id' => 'half_bad', 'values' => { 'winner' => 'b' } }] : []),
                          *(pass == 'a' ? [{ 'id' => 'half_good', 'values' => { 'winner' => 'a' } }] : []),
                          { 'id' => 'mine', 'values' => { 'winner' => 'b' } }
                        ])
    end

    result = GenieEval::Labeling.merge('comparator')

    assert_equal [1, 2, 2], result.values_at(:promoted, :queued, :dropped)
    assert_equal(%w[half_good mine], result[:queue].map { |q| q['id'] },
                 'a missing pass waits only while the other agrees; drafts without the flag go to a human')
    cells.each do |cell|
      assert_equal(%w[clear], Store.cases(cell).map { |c| c['id'] })
      assert_equal cell, Store.cases(cell).first['cell']
      assert_equal({ 'winner' => 'a' }, Store.gold(cell)['clear']['gold'])
      assert_equal 'crowd, confirmed by 2 blind passes', Store.gold(cell)['clear']['labeled_by']
    end

    Store.write_jsonl(GenieEval.path('labeling', 'comparator', 'pass_b.jsonl'),
                      [{ 'id' => 'clear', 'values' => { 'winner' => 'A' } }])
    assert_raises(GenieEval::Error, 'a broken label is not a silent drop') { GenieEval::Labeling.merge('comparator') }
  end

  def test_labeling_scores_a_bias_pair_from_both_texts
    cell = 'scorer.by_jury_bench'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'scorer', 'weight' => 1 }])
    draft = lambda do |id|
      { 'id' => id, 'cell' => cell, 'source' => 'drafted', 'tags' => { 'bias' => 'authority' }, 'why' => 'w',
        'input' => { 'text' => 't', 'twin' => 't, says a professor', 'criteria' => 'c' },
        'gold' => { 'band' => [40, 80], 'max_gap' => 10 } }
    end
    Store.write_jsonl(GenieEval.path('labeling', 'drafts', "#{cell}.jsonl"), [draft.call('close'), draft.call('apart')])
    %w[a b].each do |pass|
      Store.write_jsonl(GenieEval.path('labeling', cell, "pass_#{pass}.jsonl"), [
                          { 'id' => 'close', 'values' => { 'score' => { 'text' => 60, 'twin' => 65 } } },
                          { 'id' => 'apart', 'values' => { 'score' => { 'text' => 50, 'twin' => pass == 'a' ? 52 : 75 } } }
                        ])
    end

    result = GenieEval::Labeling.merge(cell)

    assert_equal [1, 1], result.values_at(:promoted, :queued)
    assert_equal({ 'band' => [40, 80], 'max_gap' => 10 }, Store.gold(cell)['close']['gold'])
  end

  def test_labeling_a_lister_case_checks_each_labelers_list
    cell = 'lister.with_feud'
    Store.write_json(GenieEval.path('cells.json'), [{ 'id' => cell, 'grader' => 'lister', 'weight' => 1 }])
    gold = { 'checks' => [{ 'type' => 'top_k_any', 'k' => 1, 'any_of' => ['apple'] },
                          { 'type' => 'no_item', 'any_of' => ['lychee'] }] }
    Store.write_jsonl(GenieEval.path('labeling', 'drafts', "#{cell}.jsonl"), %w[agreed split].map do |id|
      { 'id' => id, 'cell' => cell, 'source' => 'drafted', 'tags' => {}, 'why' => 'w', 'input' => { 'theme' => 't' }, 'gold' => gold }
    end)
    %w[a b].each do |pass|
      Store.write_jsonl(GenieEval.path('labeling', cell, "pass_#{pass}.jsonl"), [
                          { 'id' => 'agreed', 'values' => { 'list' => %w[Apples Cherry] } },
                          { 'id' => 'split', 'values' => { 'list' => pass == 'a' ? %w[Apple] : %w[Apple Lychee] } }
                        ])
    end

    result = GenieEval::Labeling.merge(cell)

    assert_equal [1, 1], result.values_at(:promoted, :queued)
    assert_equal gold, Store.gold(cell)['agreed']['gold']
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../eval/lib/genie_eval'

class GenieEvalGradersTest < Minitest::Test
  Graders = GenieEval::Graders

  def output(data, reasoning: 'because')
    { 'output' => { 'data' => data, 'reasoning' => reasoning } }
  end

  def test_extractor_assigns_the_five_outcomes
    gold = { 'fields' => {
      'name' => { 'present' => true, 'check' => 'eq', 'value' => 'Alex Rivera' },
      'years' => { 'present' => true, 'check' => 'gte', 'value' => 8 },
      'skills' => { 'present' => true, 'check' => 'nonempty' },
      'salary' => { 'present' => false },
      'phone' => { 'present' => false }
    } }
    data = { 'name' => ' alex  rivera ', 'years' => '5 years', 'skills' => [], 'salary' => nil, 'phone' => '555' }

    grade = Graders::Extractor.grade(gold, output(data))

    assert_equal(
      { 'name' => 'correct', 'years' => 'wrong_value', 'skills' => 'omission',
        'salary' => 'correct_abstention', 'phone' => 'invention' },
      grade.detail['fields']
    )
    refute grade.pass
  end

  def test_extractor_passes_when_every_field_is_right
    gold = { 'fields' => { 'ok' => { 'present' => true, 'check' => 'eq', 'value' => true },
                           'none' => { 'present' => false } } }

    assert Graders::Extractor.grade(gold, output({ 'ok' => true })).pass
  end

  def test_extractor_optional_field_accepts_absent_or_a_matching_value
    spec = { 'present' => 'optional', 'check' => 'contains_any', 'value' => ['perpetual'] }

    assert_equal 'correct_abstention', Graders::Extractor.outcome(spec, nil)
    assert_equal 'correct', Graders::Extractor.outcome(spec, 'Perpetual')
    assert_equal 'wrong_value', Graders::Extractor.outcome(spec, '2027-01-01')
  end

  def test_comparator_requires_the_gold_winner_in_both_orders
    record = { 'orders' => { 'ab' => { 'winner' => 'a' }, 'ba' => { 'winner' => 'b' } } }
    grade = Graders::Comparator.grade({ 'winner' => 'a' }, record)

    refute grade.pass
    refute grade.detail['consistent']
    assert Graders::Comparator.grade({ 'winner' => 'either' }, record).pass
  end

  def test_comparator_passes_a_consistent_correct_pick
    record = { 'orders' => { 'ab' => { 'winner' => 'b' }, 'ba' => { 'winner' => 'b' } } }

    assert Graders::Comparator.grade({ 'winner' => 'b' }, record).pass
  end

  def test_lister_checks
    items = ['Pepperoni', 'Extra cheese', 'Mushrooms', 'Price comparison']
    gold = { 'checks' => [
      { 'type' => 'top_k_any', 'k' => 1, 'any_of' => %w[pepperoni cheese] },
      { 'type' => 'min_groups', 'min' => 2, 'groups' => [['mushroom'], ['olive'], ['cheese']] },
      { 'type' => 'no_item', 'any_of' => ['pineapple'] },
      { 'type' => 'min_items', 'n' => 4 }
    ] }

    assert Graders::Lister.grade(gold, output(items)).pass

    bottom = { 'checks' => [{ 'type' => 'bottom_k_none', 'k' => 1, 'any_of' => ['price'] }] }

    refute Graders::Lister.grade(bottom, output(items)).pass
  end

  def test_scorer_band_is_inclusive
    assert Graders::Scorer.grade({ 'band' => [60, 100] }, output(60)).pass
    refute Graders::Scorer.grade({ 'band' => [60, 100] }, output(59.9)).pass
  end

  def test_scorer_bias_pair_needs_both_scores_in_band_and_close
    gold = { 'band' => [40, 80], 'max_gap' => 10 }
    pair = ->(text, twin) { output(text).merge('twin' => { 'data' => twin }) }

    grade = Graders::Scorer.grade(gold, pair.call(55, 62))

    assert grade.pass
    assert_in_delta 7.0, grade.detail['gap']
    refute Graders::Scorer.grade(gold, pair.call(55, 70)).pass, 'too far apart'
    refute Graders::Scorer.grade(gold, pair.call(75, 85)).pass, 'twin out of band'
    refute Graders::Scorer.grade(gold, output(55)).pass, 'twin missing'
  end

  def test_errors_missing_records_and_missing_reasoning_fail
    GenieEval::Store.stub(:cell, { 'grader' => 'scorer' }) do
      gold = { 'band' => [0, 100], 'require_reasoning' => true }

      refute GenieEval::Graders.grade('scorer.by_jury_bench', gold, nil).pass
      refute GenieEval::Graders.grade('scorer.by_jury_bench', gold, { 'error' => 'boom' }).pass
      refute GenieEval::Graders.grade('scorer.by_jury_bench', gold, output(50, reasoning: '')).pass
      assert GenieEval::Graders.grade('scorer.by_jury_bench', gold, output(50)).pass
    end
  end
end

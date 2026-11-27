# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/eval'

# The built-in graders, graded through ActiveGenie::Eval::Graders.grade as a run would: fields, band,
# list and winner, twin rows and require_reasoning.
class AppEvalGradersTest < Minitest::Test
  Graders = ActiveGenie::Eval::Graders

  def grade(grader, gold, record)
    definition = ActiveGenie::Eval::Definition.new(name: 'x', dir: Dir.pwd)
    definition.grader = grader
    Graders.grade(definition, gold, record)
  end

  def output(data, reasoning: 'because')
    { 'output' => { 'data' => data, 'reasoning' => reasoning } }
  end

  def pair(text, twin, reasoning: 'because')
    output(text).merge('twin' => { 'data' => twin, 'reasoning' => reasoning })
  end

  def test_fields_assigns_the_five_outcomes
    gold = { 'fields' => {
      'name' => { 'present' => true, 'check' => 'eq', 'value' => 'Alex Rivera' },
      'years' => { 'present' => true, 'check' => 'gte', 'value' => 8 },
      'skills' => { 'present' => true, 'check' => 'nonempty' },
      'salary' => { 'present' => false },
      'phone' => { 'present' => false }
    } }
    data = { 'name' => ' alex  rivera ', 'years' => '5 years', 'skills' => [], 'salary' => nil, 'phone' => '555' }
    result = grade('fields', gold, output(data))

    assert_equal({ 'name' => 'correct', 'years' => 'wrong_value', 'skills' => 'omission',
                   'salary' => 'correct_abstention', 'phone' => 'invention' }, result.detail['fields'])
    refute result.pass
  end

  def test_an_optional_field_accepts_absent_or_a_matching_value
    spec = { 'present' => 'optional', 'check' => 'contains_any', 'value' => ['perpetual'] }

    assert_equal 'correct_abstention', Graders::Fields.outcome(spec, nil)
    assert_equal 'correct', Graders::Fields.outcome(spec, 'Perpetual')
    assert_equal 'wrong_value', Graders::Fields.outcome(spec, '2027-01-01')
  end

  def test_winner_needs_the_gold_side_in_both_orders
    split = grade('winner', { 'winner' => 'a' }, output({ 'ab' => 'a', 'ba' => 'b' }))

    refute split.pass
    refute split.detail['consistent']
    assert grade('winner', { 'winner' => 'either' }, output({ 'ab' => 'a', 'ba' => 'b' })).pass
    refute grade('winner', { 'winner' => 'either' }, output({ 'ab' => 'a', 'ba' => nil })).pass, 'no pick is not a tie'
    assert grade('winner', { 'winner' => 'b' }, output({ 'ab' => 'b', 'ba' => 'b' })).detail['consistent']
    assert grade('winner', { 'winner' => 'b' }, output('b')).pass, 'a single pick works too'
  end

  def test_list_checks
    items = ['Pepperoni', 'Extra cheese', 'Mushrooms', 'Price comparison']
    gold = { 'checks' => [
      { 'type' => 'top_k_any', 'k' => 1, 'any_of' => %w[pepperoni cheese] },
      { 'type' => 'min_groups', 'min' => 2, 'groups' => [['mushroom'], ['olive'], ['cheese']] },
      { 'type' => 'no_item', 'any_of' => ['pineapple'] },
      { 'type' => 'min_items', 'n' => 4 }
    ] }

    assert grade('list', gold, output(items)).pass
    refute grade('list', { 'checks' => [{ 'type' => 'bottom_k_none', 'k' => 1, 'any_of' => ['price'] }] }, output(items)).pass
  end

  def test_list_max_items_caps_the_count_and_pairs_with_min_items_for_an_exact_count
    at_most = { 'checks' => [{ 'type' => 'max_items', 'n' => 3 }] }

    assert Graders::List.pass?(at_most, %w[a b]), 'under the limit'
    assert Graders::List.pass?(at_most, %w[a b c]), 'at the limit'
    refute Graders::List.pass?(at_most, %w[a b c d]), 'over the limit'

    exactly = { 'checks' => [{ 'type' => 'min_items', 'n' => 3 }, { 'type' => 'max_items', 'n' => 3 }] }
    result = grade('list', exactly, output(%w[a b c d]))

    refute result.pass
    assert_equal({ 'min_items' => true, 'max_items' => false }, result.detail['checks'])
    assert_equal 4, result.detail['items']
    assert grade('list', exactly, output(%w[a b c])).pass
    refute grade('list', exactly, output(%w[a b])).pass
  end

  def test_list_terms_match_where_a_word_starts
    rain = { 'checks' => [{ 'type' => 'any_item', 'any_of' => ['rain'] }] }

    assert Graders::List.pass?(rain, ['Rainy weather'])
    refute Graders::List.pass?(rain, ['Missed the train'])
    refute Graders::List.pass?({ 'checks' => [{ 'type' => 'top_k_any', 'k' => 1, 'any_of' => ['apple'] }] }, ['Pineapple'])
    assert Graders::List.pass?({ 'checks' => [{ 'type' => 'any_item', 'any_of' => [' Ice  Cream'] }] }, ['Vanilla ice cream'])
  end

  def test_list_min_groups_fills_each_group_with_a_different_item
    gold = { 'checks' => [{ 'type' => 'min_groups', 'min' => 2, 'groups' => [['ice'], ['ice cream']] }] }

    refute Graders::List.pass?(gold, ['Ice cream']), 'one answer fills one group'
    assert Graders::List.pass?(gold, ['Ice cream', 'Ice cubes'])

    three = { 'checks' => [{ 'type' => 'min_groups', 'min' => 3, 'groups' => [['ice'], ['cream'], ['cube']] }] }

    assert Graders::List.pass?(three, ['Ice cream', 'Ice cubes', 'Cream soda'])
    refute Graders::List.pass?(three, ['Ice cream', 'Ice cubes'])
  end

  def test_band_is_inclusive
    assert grade('band', { 'band' => [60, 100] }, output(60)).pass
    refute grade('band', { 'band' => [60, 100] }, output(59.9)).pass
  end

  def test_a_twin_pair_needs_both_scores_in_band_and_close
    gold = { 'band' => [40, 80], 'max_gap' => 10 }
    close = grade('band', gold, pair(55, 62))

    assert close.pass
    assert_in_delta 7.0, close.detail['gap']
    refute grade('band', gold, pair(55, 70)).pass, 'too far apart'
    refute grade('band', gold, pair(75, 85)).pass, 'twin out of band'
  end

  def test_a_twin_pair_is_graded_on_the_gap_it_reports
    gold = { 'band' => [0, 100], 'max_gap' => 10 }

    assert_in_delta 10.0, grade('band', gold, pair(50.0, 60.04)).detail['gap']
    assert grade('band', gold, pair(50.0, 60.04)).pass, 'a gap shown as 10.0 is within a max_gap of 10'
    refute grade('band', gold, pair(50.0, 60.06)).pass
  end

  def test_a_twin_of_any_grader_must_pass_both_times
    gold = { 'fields' => { 'intent' => { 'present' => true, 'check' => 'eq', 'value' => 'refund' } } }

    assert grade('fields', gold, pair({ 'intent' => 'refund' }, { 'intent' => 'refund' })).pass
    refute grade('fields', gold, pair({ 'intent' => 'refund' }, { 'intent' => 'billing' })).pass
  end

  def test_errors_missing_records_and_missing_reasoning_fail
    gold = { 'band' => [0, 100], 'require_reasoning' => true }

    refute grade('band', gold, nil).pass
    refute grade('band', gold, { 'error' => 'boom' }).pass
    refute grade('band', gold, output(50, reasoning: '')).pass
    assert grade('band', gold, output(50)).pass
  end

  def test_a_twin_pair_needs_reasoning_for_both_texts
    gold = { 'band' => [0, 100], 'max_gap' => 10, 'require_reasoning' => true }

    assert grade('band', gold, pair(50, 52)).pass
    refute grade('band', gold, pair(50, 52, reasoning: '')).pass
  end
end

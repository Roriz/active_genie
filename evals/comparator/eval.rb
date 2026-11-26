# frozen_string_literal: true

# ActiveGenie::Comparator: which of two players better fits the criteria. The two methods are
# variants on the same cases, so the report compares them head to head. Each case runs in both
# orders, and the pick is mapped back to the case's own a/b, so position bias shows as a failure.
ActiveGenie::Eval.define 'comparator' do
  both_orders = lambda do |method, input|
    a, b = input.values_at('player_a', 'player_b')
    config = input['config'] || {}
    ab = ActiveGenie::Comparator.public_send(method, a, b, input['criteria'], config:)
    ba = ActiveGenie::Comparator.public_send(method, b, a, input['criteria'], config:)
    side = { a => 'a', b => 'b' }
    { 'ab' => side[ab.data], 'ba' => side[ba.data], 'reasoning' => { 'ab' => ab.reasoning, 'ba' => ba.reasoning } }
  end

  variant(:by_debate) { |input| both_orders.call(:by_debate, input) }
  variant(:by_fight) { |input| both_orders.call(:by_fight, input) }

  grader :winner
end

# frozen_string_literal: true

# ActiveGenie::Scorer.by_jury_bench: a 0-100 score from a bench of juries. Bias pairs are twin rows:
# the same text with one change that should not matter (verbosity, authority, ...), which must land in
# the same band and within `max_gap` of each other.
ActiveGenie::Eval.define 'scorer_by_jury_bench' do
  call do |input, context|
    config = input['config'] || {}
    juries = input['juries']
    # Both texts of a pair share the juries, picked once from the text, so the gap comes from the
    # change alone and not from two different benches.
    if juries.nil? && context.row['twin']
      juries = context.shared[:juries] ||=
        ActiveGenie::Lister.with_juries(input['text'], input['criteria'], config:).data
    end
    ActiveGenie::Scorer.by_jury_bench(input['text'], input['criteria'], juries:, config:)
  end

  grader :band
end

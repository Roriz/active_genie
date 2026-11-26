# frozen_string_literal: true

# ActiveGenie::Lister.with_feud: the answers a crowd would give, Family Feud style. See evals/README.md.
ActiveGenie::Eval.define 'lister_with_feud' do
  call { |input| ActiveGenie::Lister.with_feud(input['theme'], config: input['config'] || {}) }

  grader :list
end

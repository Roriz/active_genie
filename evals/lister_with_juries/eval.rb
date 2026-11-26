# frozen_string_literal: true

# ActiveGenie::Lister.with_juries: the experts who should grade a text against its criteria.
ActiveGenie::Eval.define 'lister_with_juries' do
  call { |input| ActiveGenie::Lister.with_juries(input['text'], input['criteria'], config: input['config'] || {}) }

  grader :list
end

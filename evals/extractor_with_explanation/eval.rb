# frozen_string_literal: true

# ActiveGenie::Extractor.with_explanation: the fields a schema asks for, pulled from a text. See evals/README.md.
ActiveGenie::Eval.define 'extractor_with_explanation' do
  call do |input|
    schema = JSON.parse(JSON.generate(input['schema']), symbolize_names: true) # ActiveGenie takes symbol keys
    ActiveGenie::Extractor.with_explanation(input['text'], schema, config: input['config'] || {})
  end

  grader :fields
end

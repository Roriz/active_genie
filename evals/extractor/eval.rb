# frozen_string_literal: true

# ActiveGenie::Extractor: the fields a schema asks for, pulled from a text. `data` and
# `with_explanation` are variants on the same cases, so the report compares them head to head.
# See evals/README.md.
ActiveGenie::Eval.define 'extractor' do
  extract = lambda do |method, input|
    schema = JSON.parse(JSON.generate(input['schema']), symbolize_names: true) # ActiveGenie takes symbol keys
    ActiveGenie::Extractor.public_send(method, input['text'], schema, config: input['config'] || {})
  end

  variant(:data) { |input| extract.call(:data, input) }
  variant(:with_explanation) { |input| extract.call(:with_explanation, input) }

  grader :fields
end

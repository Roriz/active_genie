# frozen_string_literal: true

module GenieEval
  # Calls the real ActiveGenie method for a cell and turns the result into a JSON-safe record.
  module Executor
    CALLS = {
      'extractor.data' => ->(i, c) { ActiveGenie::Extractor.data(i['text'], i['schema'], config: c) },
      'extractor.with_explanation' => lambda { |i, c|
        ActiveGenie::Extractor.with_explanation(i['text'], i['schema'], config: c)
      },
      'extractor.with_litote' => ->(i, c) { ActiveGenie::Extractor.with_litote(i['text'], i['schema'], config: c) },
      'comparator.by_debate' => lambda { |i, c|
        ActiveGenie::Comparator.by_debate(i['player_a'], i['player_b'], i['criteria'], config: c)
      },
      'comparator.by_fight' => lambda { |i, c|
        ActiveGenie::Comparator.by_fight(i['player_a'], i['player_b'], i['criteria'], config: c)
      },
      'lister.with_feud' => ->(i, c) { ActiveGenie::Lister.with_feud(i['theme'], config: c) },
      'lister.with_juries' => ->(i, c) { ActiveGenie::Lister.with_juries(i['text'], i['criteria'], config: c) },
      'scorer.by_jury_bench' => lambda { |i, c|
        ActiveGenie::Scorer.by_jury_bench(i['text'], i['criteria'], juries: i['juries'], config: c)
      }
    }.freeze

    module_function

    # Returns the record body for one case (without id/usage/timing, which the runner adds).
    def call(cell_id, input)
      input = deep_symbolize_schema(input)
      config = input['config'] || {}
      return comparator(cell_id, input, config) if cell_id.start_with?('comparator.')

      return scorer_pair(input, config) if input['twin']

      { 'output' => serialize(CALLS.fetch(cell_id).call(input, config)) }
    end

    # A scorer bias pair scores the text and its twin with the same juries: the case's own, or juries
    # picked once from the text. Picking them per text would mix jury choice into the gap.
    def scorer_pair(input, config)
      juries = input['juries'] || ActiveGenie::Lister.with_juries(input['text'], input['criteria'], config:).data
      shared = input.merge('juries' => juries)
      call = CALLS.fetch('scorer.by_jury_bench')
      { 'output' => serialize(call.call(shared, config)),
        'twin' => serialize(call.call(shared.merge('text' => input['twin']), config)),
        'juries' => juries }
    end

    # Comparators run in both orders; winners are mapped back to the case's own a/b labels.
    def comparator(cell_id, input, config)
      call = CALLS.fetch(cell_id)
      a = input['player_a']
      b = input['player_b']
      ab = call.call(input, config)
      ba = call.call(input.merge('player_a' => b, 'player_b' => a), config)
      side = ->(winner) { { a => 'a', b => 'b' }[winner] }
      {
        'orders' => {
          'ab' => serialize(ab).merge('winner' => side.call(ab.data)),
          'ba' => serialize(ba).merge('winner' => side.call(ba.data))
        }
      }
    end

    def serialize(result)
      {
        'data' => JSON.parse(JSON.generate(result.data)),
        'reasoning' => result.reasoning,
        'metadata' => scalar_metadata(result.metadata)
      }
    end

    # Keep only small scalar metadata (e.g. winner probabilities); raw provider payloads are large.
    def scalar_metadata(metadata)
      return {} unless metadata.is_a?(Hash)

      metadata.select { |_k, v| v.is_a?(Numeric) || v.is_a?(String) || v == true || v == false }
              .transform_keys(&:to_s)
              .reject { |_k, v| v.is_a?(String) && v.size > 2000 }
    end

    # Extractor schemas are written with string keys in JSON; ActiveGenie expects symbols.
    def deep_symbolize_schema(input)
      return input unless input['schema']

      input.merge('schema' => JSON.parse(JSON.generate(input['schema']), symbolize_names: true))
    end
  end
end

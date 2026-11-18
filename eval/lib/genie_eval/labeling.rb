# frozen_string_literal: true

module GenieEval
  # Turns drafted cases into gold with blind labeling passes, as in document-review-golden:
  #
  #   eval/labeling/drafts/<cell>.jsonl     drafted cases, each with its intended gold
  #   eval/labeling/<cell>/pass_a.jsonl     blind pass A: field values from labeler A
  #   eval/labeling/<cell>/pass_b.jsonl     blind pass B
  #   eval/labeling/<cell>/decisions.jsonl  human decisions, append-only; the latest per (id, field) wins
  #   eval/labeling/<cell>/queue.jsonl      what still needs a decision (rewritten on every merge)
  #
  # A field is agreed when the drafted gold accepts both passes' values, using the same matchers as
  # grading. A case enters the test pool when every field is agreed or decided, and is not excluded.
  module Labeling
    FIELD_ACTIONS = %w[set accept].freeze

    module_function

    def merge(cell)
      Store.cell(cell) # an unknown cell raises here, before any file is written
      drafted = drafts(cell)
      raise Error, "no drafted cases for #{cell} in eval/labeling/drafts/" if drafted.empty?

      decisions = latest_decisions(cell)
      passes = %w[a b].to_h { |p| [p, pass(cell, p)] }
      promoted = []
      queue = []
      drafted.each do |draft|
        decided = decisions[draft['id']] || {}
        next if decided[nil]&.fetch('action') == 'exclude'

        open = open_fields(draft, passes, decided)
        open.empty? ? promoted << resolve(draft, decided) : queue.concat(open)
      end
      write(cell, drafted, promoted, queue)
      { promoted: promoted.size, queued: queue.map { |q| q['id'] }.uniq.size, queue: }
    end

    def drafts(cell)
      Store.read_jsonl(GenieEval.path('labeling', 'drafts', "#{cell}.jsonl"))
    end

    # Latest successful labeling per case id.
    def pass(cell, name)
      rows = Store.read_jsonl(GenieEval.path('labeling', cell, "pass_#{name}.jsonl")).reject { |r| r['error'] }
      rows.to_h { |r| [r['id'], r] }
    end

    # { id => { field_or_nil => decision } }, latest wins.
    def latest_decisions(cell)
      Store.read_jsonl(GenieEval.path('labeling', cell, 'decisions.jsonl')).each_with_object({}) do |d, out|
        if d['field'] && !FIELD_ACTIONS.include?(d['action'])
          raise Error, "#{cell} decision #{d['id']}.#{d['field']}: action #{d['action'].inspect} (a field takes set or accept)"
        end

        (out[d['id']] ||= {})[d['field']] = d
      end
    end

    def open_fields(draft, passes, decided)
      values = passes.transform_values { |rows| rows[draft['id']] }
      draft['gold']['fields'].filter_map do |field, spec|
        next if decided.key?(field)
        next if values.values.all? { |row| row && accepts?(spec, row['values'][field]) }

        { 'id' => draft['id'], 'field' => field, 'drafted' => spec,
          'pass_a' => values['a']&.dig('values', field), 'pass_b' => values['b']&.dig('values', field),
          'unlabeled' => values.select { |_k, row| row.nil? }.keys }
      end
    end

    def accepts?(spec, value)
      Graders::Extractor::RIGHT.include?(Graders::Extractor.outcome(spec, value))
    end

    # Decided fields replace the drafted spec ("set") or keep it ("accept").
    def resolve(draft, decided)
      fields = draft['gold']['fields'].to_h do |field, spec|
        decision = decided[field]
        [field, decision && decision['action'] == 'set' ? decision.fetch('spec') : spec]
      end
      draft.merge('gold' => draft['gold'].merge('fields' => fields))
    end

    def write(cell, drafts, promoted, queue)
      Store.write_jsonl(GenieEval.path('labeling', cell, 'queue.jsonl'), queue)
      cases = promoted.map { |d| d.slice('id', 'cell', 'source', 'tags', 'input') }
      gold = promoted.map do |d|
        { 'id' => d['id'], 'gold' => d['gold'], 'why' => d['why'],
          'labeled_by' => 'drafted, 2 blind passes, human decisions' }
      end
      drafted = drafts.to_set { |d| d['id'] }
      Store.replace_cases(cell, cases, gold) { |id| drafted.include?(id) }
    end
  end
end

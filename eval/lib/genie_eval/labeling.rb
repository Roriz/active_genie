# frozen_string_literal: true

module GenieEval
  # Turns drafted cases into gold with blind labeling passes, as in document-review-golden:
  #
  #   eval/labeling/drafts/<set>.jsonl     drafted cases, each with its intended gold
  #   eval/labeling/<set>/pass_a.jsonl     blind pass A: the values labeler A gave
  #   eval/labeling/<set>/pass_b.jsonl     blind pass B
  #   eval/labeling/<set>/decisions.jsonl  human decisions, append-only; the latest per (id, field) wins
  #   eval/labeling/<set>/queue.jsonl      what still needs a decision (rewritten on every merge)
  #
  # A set is usually one cell. A draft may name several `cells` instead, so the same cases are
  # labeled once and feed each of them (comparator.by_debate and by_fight share theirs).
  #
  # Each graded field of the gold is labeled: the extractor's `fields`, or a comparator's `winner`.
  # A field is agreed when the drafted gold accepts both passes' values, using the same matchers as
  # grading. A case enters the test pool when every field is agreed or decided, and is not excluded.
  # A draft whose gold came from a noisy source (`on_disagreement: drop`) is dropped on any
  # disagreement instead of queued: only its clear cases are kept.
  module Labeling
    FIELD_ACTIONS = %w[set accept].freeze

    module_function

    def merge(set)
      drafted = drafts(set)
      raise Error, "no drafted cases for #{set} in eval/labeling/drafts/" if drafted.empty?

      drafted.flat_map { |d| cells(d) }.uniq.each { |cell| Store.cell(cell) } # an unknown cell raises before any write
      decisions = latest_decisions(set)
      passes = %w[a b].to_h { |p| [p, pass(set, p)] }
      promoted = []
      queue = []
      dropped = 0
      drafted.each do |draft|
        decided = decisions[draft['id']] || {}
        next if decided[nil]&.fetch('action') == 'exclude'

        open = open_fields(draft, passes, decided)
        if open.empty? then promoted << resolve(draft, decided)
        elsif draft['on_disagreement'] == 'drop' && open.none? { |q| q['unlabeled'].any? } then dropped += 1
        else queue.concat(open)
        end
      end
      write(set, drafted, promoted, queue)
      { promoted: promoted.size, queued: queue.map { |q| q['id'] }.uniq.size, dropped:, queue: }
    end

    def drafts(set)
      Store.read_jsonl(GenieEval.path('labeling', 'drafts', "#{set}.jsonl"))
    end

    # Latest successful labeling per case id.
    def pass(set, name)
      rows = Store.read_jsonl(GenieEval.path('labeling', set, "pass_#{name}.jsonl")).reject { |r| r['error'] }
      rows.to_h { |r| [r['id'], r] }
    end

    # { id => { field_or_nil => decision } }, latest wins.
    def latest_decisions(set)
      Store.read_jsonl(GenieEval.path('labeling', set, 'decisions.jsonl')).each_with_object({}) do |d, out|
        if d['field'] && !FIELD_ACTIONS.include?(d['action'])
          raise Error, "#{set} decision #{d['id']}.#{d['field']}: action #{d['action'].inspect} (a field takes set or accept)"
        end

        (out[d['id']] ||= {})[d['field']] = d
      end
    end

    def open_fields(draft, passes, decided)
      values = passes.transform_values { |rows| rows[draft['id']] }
      fields(draft['gold']).filter_map do |field, spec|
        next if decided.key?(field)
        next if values.values.all? { |row| row && accepts?(spec, row['values'][field]) }

        { 'id' => draft['id'], 'field' => field, 'drafted' => spec,
          'pass_a' => values['a']&.dig('values', field), 'pass_b' => values['b']&.dig('values', field),
          'unlabeled' => values.select { |_k, row| row.nil? }.keys }
      end
    end

    # The labeled fields of a gold: { name => spec }.
    def fields(gold)
      gold.key?('fields') ? gold['fields'] : { 'winner' => gold }
    end

    def accepts?(spec, value)
      return value == spec['winner'] if spec.key?('winner')

      Graders::Extractor::RIGHT.include?(Graders::Extractor.outcome(spec, value))
    end

    # Decided fields replace the drafted spec ("set") or keep it ("accept").
    def resolve(draft, decided)
      chosen = fields(draft['gold']).to_h do |field, spec|
        decision = decided[field]
        [field, decision && decision['action'] == 'set' ? decision.fetch('spec') : spec]
      end
      gold = draft['gold'].key?('fields') ? draft['gold'].merge('fields' => chosen) : chosen.fetch('winner')
      draft.merge('gold' => gold)
    end

    def write(set, drafts, promoted, queue)
      Store.write_jsonl(GenieEval.path('labeling', set, 'queue.jsonl'), queue)
      drafted = drafts.to_set { |d| d['id'] }
      drafts.flat_map { |d| cells(d) }.uniq.each do |cell|
        mine = promoted.select { |d| cells(d).include?(cell) }
        cases = mine.map { |d| { 'id' => d['id'], 'cell' => cell }.merge(d.slice('source', 'tags', 'input')) }
        gold = mine.map do |d|
          { 'id' => d['id'], 'gold' => d['gold'], 'why' => d['why'],
            'labeled_by' => d['labeled_by'] || 'drafted, 2 blind passes, human decisions' }
        end
        Store.replace_cases(cell, cases, gold) { |id| drafted.include?(id) }
      end
    end

    def cells(draft)
      draft['cells'] || [draft.fetch('cell')]
    end
  end
end

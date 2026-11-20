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
  # A pass row's values are always in the draft's terms: a comparator `winner` names the draft's
  # player_a or player_b, whatever `order` the labeler saw the players in.
  #
  # A set is usually one cell. A draft may name several `cells` instead, so the same cases are
  # labeled once and feed each of them (comparator.by_debate and by_fight share theirs).
  #
  # Each graded field of the gold is labeled: the extractor's `fields`, a comparator's `winner`, a
  # scorer's `score` (a number, or { "text", "twin" } numbers for a bias pair), or a lister's `list`.
  # A field is agreed when the drafted gold accepts both passes' values, using the same matchers as
  # grading. A case enters the test pool when every field is agreed or decided, and is not excluded.
  # A decision with no `field` is about the whole case: `exclude` keeps it out, `include` undoes that.
  # A draft whose gold came from a noisy source (`on_disagreement: drop`) is dropped as soon as a
  # pass disagrees, instead of queued: only its clear cases are kept. A draft may name its source in
  # `labeled_by` (default "drafted"); the gold adds whether the passes confirmed it or a human settled it.
  module Labeling
    FIELD_ACTIONS = %w[set accept].freeze
    CASE_ACTIONS = %w[exclude include].freeze

    module_function

    def merge(set)
      drafted = drafts(set)
      raise Error, "no drafted cases for #{set} in eval/labeling/drafts/" if drafted.empty?

      targets = drafted.flat_map { |d| cells(d) }.uniq
      targets.each { |cell| Store.cell(cell) } # an unknown cell raises before any write
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
        elsif draft['on_disagreement'] == 'drop' && open.any? { |q| disagreed?(q) } then dropped += 1
        else queue.concat(open)
        end
      end
      write(set, targets, drafted, promoted, queue)
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
        if !d['field'] && !CASE_ACTIONS.include?(d['action'])
          raise Error, "#{set} decision #{d['id']}: action #{d['action'].inspect} (a case takes exclude or include)"
        end
        raise Error, "#{set} decision #{d['id']}.#{d['field']}: a set needs its spec" if d['action'] == 'set' && !d.key?('spec')

        (out[d['id']] ||= {})[d['field']] = d
      end
    end

    # A pass row with no value for a field has not labeled it: it is `unlabeled`, so a drop draft
    # waits for a relabel unless the other pass already disagrees.
    def open_fields(draft, passes, decided)
      values = passes.transform_values { |rows| rows[draft['id']] }
      fields(draft['gold']).filter_map do |field, spec|
        next if decided.key?(field)
        next if values.values.all? { |row| row && accepts?(spec, row.dig('values', field)) }

        { 'id' => draft['id'], 'field' => field, 'drafted' => spec,
          'pass_a' => values['a']&.dig('values', field), 'pass_b' => values['b']&.dig('values', field),
          'unlabeled' => values.select { |_k, row| row.nil? || !row['values']&.key?(field) }.keys }
      end
    end

    # A pass that labeled this open field gave a value the drafted gold does not accept.
    def disagreed?(open_field)
      (%w[a b] - open_field['unlabeled']).any? { |p| !accepts?(open_field['drafted'], open_field["pass_#{p}"]) }
    end

    # The labeled fields of a gold: { name => spec }. Other graders' gold has no labeling yet.
    def fields(gold)
      return gold['fields'] if gold.key?('fields')
      return { 'winner' => gold } if gold.key?('winner')
      return { 'score' => gold } if gold.key?('band')
      return { 'list' => gold } if gold.key?('checks')

      raise Error, 'labeling takes extractor fields, a comparator winner, a scorer band or lister checks, ' \
                   "not a gold with #{gold.keys.join(', ')}"
    end

    # A comparator pass value outside a, b and either is a broken label, not a disagreement.
    def accepts?(spec, value)
      if spec.key?('winner')
        unless value.nil? || Graders::Comparator::WINNERS.include?(value)
          raise Error, "a pass gave winner #{value.inspect}; it takes #{Graders::Comparator::WINNERS.join(', ')}"
        end

        return value == spec['winner']
      end
      return scored_within?(spec, value) if spec.key?('band')
      return listed?(spec, value) if spec.key?('checks')

      Graders::Extractor::RIGHT.include?(Graders::Extractor.outcome(spec, value))
    end

    # No answers are not agreement, even with a gold of only `no_item` checks. A value that is not a
    # list is a broken label: as a single item, a string would contain every answer it names.
    def listed?(spec, value)
      return false if Matchers.absent?(value)
      raise Error, "a pass gave list #{value.inspect}; it takes an array of answers" unless value.is_a?(Array)

      Graders::Lister.pass?(spec, value)
    end

    def scored_within?(spec, value)
      scores = value.is_a?(Hash) ? value : { 'text' => value }
      Graders::Scorer.within?(spec, Matchers.number(scores['text']), Matchers.number(scores['twin']))
    end

    # Decided fields replace the drafted spec ("set") or keep it ("accept"). A comparator's winner, a
    # scorer's score or a lister's list spec is its whole gold, so a "set" decision gives e.g. {"winner": "b"}.
    def resolve(draft, decided)
      chosen = fields(draft['gold']).to_h do |field, spec|
        decision = decided[field]
        [field, decision && decision['action'] == 'set' ? decision.fetch('spec') : spec]
      end
      gold = draft['gold'].key?('fields') ? draft['gold'].merge('fields' => chosen) : chosen.values.first
      unless gold.is_a?(Hash) && %w[fields winner band checks].any? { |k| gold.key?(k) }
        raise Error, "#{draft['id']}: a winner, score or list decision's spec is all the gold, e.g. {\"winner\": \"b\"}"
      end

      draft.merge('gold' => gold, 'labeled_by' => labeled_by(draft, decided))
    end

    # Where the gold came from: the draft's source ("drafted" by default), then who settled it.
    def labeled_by(draft, decided)
      settled = decided.except(nil).any? # the nil key is a case-level decision, not a field
      "#{draft['labeled_by'] || 'drafted'}, #{settled ? 'settled by a human decision' : 'confirmed by 2 blind passes'}"
    end

    # Rewrites every cell the set has rows in: the cells its drafts name, and any cell whose gold still
    # tags rows with the set. A row whose draft was removed, or whose draft no longer names that cell,
    # is dropped there with its case and pool entry. Other sources' rows in a cell are kept.
    def write(set, targets, drafts, promoted, queue)
      Store.write_jsonl(GenieEval.path('labeling', set, 'queue.jsonl'), queue)
      tagged = tagged_ids(set)
      (targets | tagged.keys).each do |cell|
        mine = promoted.select { |d| cells(d).include?(cell) }
        cases = mine.map { |d| { 'id' => d['id'], 'cell' => cell }.merge(d.slice('source', 'tags', 'input')) }
        gold = mine.map { |d| d.slice('id', 'gold', 'why', 'labeled_by').merge('set' => set) }
        named = drafts.select { |d| cells(d).include?(cell) }.to_set { |d| d['id'] }
        owned = named | tagged.fetch(cell, Set.new)
        Store.replace_cases(cell, cases, gold) { |id| owned.include?(id) }
      end
    end

    # { cell => ids of its gold rows tagged with the set }, for each cell that has any.
    def tagged_ids(set)
      ids = Store.cells.to_h do |c|
        [c['id'], Store.gold(c['id']).values.select { |g| g['set'] == set }.to_set { |g| g['id'] }]
      end
      ids.reject { |_cell, owned| owned.empty? }
    end

    def cells(draft)
      names = draft['cells'] || [draft['cell']].compact
      return names if names.is_a?(Array) && names.any?

      raise Error, "draft #{draft['id']} names no cell or cells"
    end
  end
end

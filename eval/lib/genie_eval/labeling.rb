# frozen_string_literal: true

module GenieEval
  # Labels drafted rows with two blind passes and writes the outcome into the row's `status`:
  #
  #   eval/sets/<set>.jsonl    the rows; a drafted row starts with "status": "draft"
  #   eval/labels/<set>.jsonl  the passes: { "id", "pass": "a" | "b", "labeler", "values", ... }
  #
  # A pass's values are always in the row's terms: a comparator `winner` names the row's player_a or
  # player_b, whatever `order` the labeler saw the players in. The latest successful label per id
  # and pass counts.
  #
  # Each graded field of the gold is labeled: the extractor's `fields`, a comparator's `winner`, a
  # scorer's `score` (a number, or { "text", "twin" } numbers for a bias pair), or a lister's `list`.
  # A field is agreed when the gold accepts both passes' values, using the same matchers as grading.
  #
  #   confirmed  every field is agreed: the row runs
  #   dropped    a pass disagreed on a row from a noisy source (`on_disagreement: drop`)
  #   draft      a pass has not labeled a field yet: waits for that pass (eval:blind still shows it)
  #   queued     anything else: waits for a person
  #
  # A person settles a queued row by editing its gold (or keeping it) and setting "status": "decided",
  # or takes a row out with "excluded". Labeling never touches those, nor rows without a status.
  module Labeling
    module_function

    def merge(set)
      rows = known_rows(set)
      raise Error, "set #{set} has no rows" if rows.empty?

      rows.flat_map { |row| Array(row['cells']) }.uniq.each { |cell| Store.cell(cell) } # unknown cells raise first
      passes = passes(set)
      queue = []
      rows = rows.map do |row|
        next row unless Store::LABELED.include?(row['status'])

        open = open_fields(row, passes)
        queue.concat(open) if (status = status(row, open)) == 'queued'
        row.merge('status' => status)
      end
      Store.write_rows(set, rows)
      counts = Hash.new(0).merge(rows.map { |r| r['status'] }.tally)
      { confirmed: counts['confirmed'], queued: counts['queued'], dropped: counts['dropped'], draft: counts['draft'],
        queue: }
    end

    # A row a pass has not labeled yet stays a draft, so eval:blind keeps showing it and a person is
    # not asked to settle it before both passes are in.
    def status(row, open)
      return 'confirmed' if open.empty?
      return 'dropped' if row['on_disagreement'] == 'drop' && open.any? { |q| disagreed?(q) }
      return 'draft' if open.any? { |q| q['unlabeled'].any? }

      'queued'
    end

    def known_rows(set)
      raise Error, "no set #{set} in eval/sets/ (sets: #{Store.sets.join(', ')})" unless Store.sets.include?(set)

      Store.rows(set)
    end

    # { "a" => { id => label }, "b" => { id => label } }: the latest successful label per id.
    def passes(set)
      labels = Store.labels(set).reject { |r| r['error'] }
      odd = labels.map { |r| r['pass'] }.uniq - %w[a b]
      raise Error, "#{set} labels: pass must be a or b, not #{odd.map(&:inspect).join(', ')}" if odd.any?

      %w[a b].to_h { |p| [p, labels.select { |r| r['pass'] == p }.to_h { |r| [r['id'], r] }] }
    end

    # A pass with no value for a field has not labeled it: it is `unlabeled`, so a drop row waits
    # for a relabel unless the other pass already disagrees.
    def open_fields(row, passes)
      values = passes.transform_values { |labels| labels[row['id']] }
      fields(row['gold']).filter_map do |field, spec|
        next if values.values.all? { |label| label && accepts?(spec, label.dig('values', field)) }

        { 'id' => row['id'], 'field' => field, 'gold' => spec,
          'pass_a' => values['a']&.dig('values', field), 'pass_b' => values['b']&.dig('values', field),
          'unlabeled' => values.select { |_k, label| label.nil? || !label['values']&.key?(field) }.keys }
      end
    end

    # A pass that labeled this open field gave a value the gold does not accept.
    def disagreed?(open_field)
      (%w[a b] - open_field['unlabeled']).any? { |p| !accepts?(open_field['gold'], open_field["pass_#{p}"]) }
    end

    # The labeled fields of a gold: { name => spec }.
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

    # What a blind labeler sees: the drafted rows still waiting for a pass, without their gold or why.
    def blind(set)
      known_rows(set).select { |row| row['status'] == 'draft' }.map { |row| row.slice('id', 'cells', 'input') }
    end
  end
end

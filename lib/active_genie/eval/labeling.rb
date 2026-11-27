# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Labels drafted rows with two blind passes and writes the outcome into each row's `status`:
    #
    #   evals/<name>/datasets.jsonl  the rows; a drafted row starts with "status": "draft"
    #   evals/<name>/gold.jsonl      the passes: { "id", "pass": "a" | "b", "labeler", "values" }
    #
    # Two people (or a person and a model, or two models) answer each draft without seeing its gold;
    # `blind` prints what they get. A field is agreed when the gold accepts both passes' values, using
    # the grader's own matchers. Then:
    #
    #   confirmed  every field is agreed: the row runs
    #   dropped    a pass disagreed on a row from a noisy source (`on_disagreement: drop`)
    #   draft      a pass has not labeled a field yet
    #   queued     anything else: waits for a person
    #
    # A person settles a queued row by editing its gold (or keeping it) and setting "status": "decided",
    # or takes a row out with "excluded". Labeling never touches those, nor rows without a status.
    module Labeling
      module_function

      def merge(definition)
        rows = Store.rows(definition)
        passes = passes(definition)
        queue = []
        rows = rows.map do |row|
          next row unless Store::LABELED.include?(row['status'])

          open = open_fields(definition, row, passes)
          queue.concat(open) if (status = status(row, open)) == 'queued'
          row.merge('status' => status)
        end
        Store.write_rows(definition, rows)
        counts = Hash.new(0).merge(rows.map { |r| r['status'] }.tally)
        { confirmed: counts['confirmed'], queued: counts['queued'], dropped: counts['dropped'], draft: counts['draft'],
          queue: }
      end

      # What a blind labeler sees: the drafts still waiting for a pass, without their gold or why, but
      # with the names their `values` must answer (the gold's field names, `score` or `list`).
      def blind(definition)
        Store.rows(definition).select { |row| row['status'] == 'draft' }.map do |row|
          blind_row = row.slice('id', 'input', 'twin') # a twin row's labeler scores both texts
          next blind_row if definition.custom_grader? || !row['gold'].is_a?(Hash)

          names = definition.grader == 'fields' ? row['gold']['fields'] : fields(definition, row['gold'])
          names.is_a?(Hash) ? blind_row.merge('fields' => names.keys) : blind_row
        end
      end

      def status(row, open)
        return 'confirmed' if open.empty?
        return 'dropped' if row['on_disagreement'] == 'drop' && open.any? { |q| disagreed?(q) }
        return 'draft' if open.any? { |q| q['unlabeled'].any? }

        'queued'
      end

      # { "a" => { id => label }, "b" => { id => label } }: the latest successful label per id.
      def passes(definition)
        labels = Store.labels(definition).reject { |r| r['error'] }
        odd = labels.map { |r| r['pass'] }.uniq - %w[a b]
        raise Error, "#{definition.name}/gold.jsonl: pass must be a or b, not #{odd.map(&:inspect).join(', ')}" if odd.any?

        %w[a b].to_h { |p| [p, labels.select { |r| r['pass'] == p }.to_h { |r| [r['id'], r] }] }
      end

      # The fields not every pass agrees on. A pass with no value for a field has not labeled it
      # (`unlabeled`); `disagreed` names the passes whose value the gold rejects, and `unjudged` those
      # whose value only the judge could accept: it has no cached verdict, so a person decides.
      def open_fields(definition, row, passes)
        labels = passes.transform_values { |by_id| by_id[row['id']] }
        fields(definition, row['gold']).filter_map do |field, spec|
          unlabeled = labels.select { |_p, label| label.nil? || !label['values']&.key?(field) }.keys
          verdicts = (labels.keys - unlabeled).to_h do |p|
            [p, accepts?(definition, spec, labels[p]['values'][field], twin: !row['twin'].nil?)]
          end
          disagreed = verdicts.select { |_p, v| v == false }.keys
          unjudged = verdicts.select { |_p, v| v.nil? }.keys
          next if unlabeled.empty? && disagreed.empty? && unjudged.empty?

          { 'id' => row['id'], 'field' => field, 'gold' => spec, 'unlabeled' => unlabeled, 'disagreed' => disagreed,
            'unjudged' => unjudged, 'pass_a' => labels['a']&.dig('values', field),
            'pass_b' => labels['b']&.dig('values', field) }
        end
      end

      def disagreed?(open_field)
        open_field['disagreed'].any?
      end

      # The labeled fields of a gold: { name => spec }. A labeler answers each field's name: a `fields`
      # gold's own field names, `score` for band and rubric (a number, or {"text", "twin"} numbers for a
      # twin row), `list` for list, `winner` for winner ("a", "b" or "either", in the row's own terms).
      def fields(definition, gold)
        if definition.custom_grader?
          raise Error,
                "#{definition.name}: a custom grader's rows can't be labeled; set their status by hand"
        end

        case definition.grader
        when 'fields' then gold.fetch('fields')
        when 'band', 'rubric' then { 'score' => gold }
        when 'list' then { 'list' => gold }
        when 'winner' then { 'winner' => gold }
        end
      end

      # true or false, or nil when only the judge could accept the value and it has not ruled on it.
      def accepts?(definition, spec, value, twin: false)
        case definition.grader
        when 'band', 'rubric' then scored_within?(spec, value, twin:)
        when 'winner'
          unless value.nil? || Graders::Winner::SIDES.include?(value)
            raise Error, "a pass gave winner #{value.inspect}; it takes #{Graders::Winner::SIDES.join(', ')}"
          end

          value == spec['winner']
        when 'list'
          return false if Matchers.absent?(value)
          raise Error, "a pass gave list #{value.inspect}; it takes an array of answers" unless value.is_a?(Array)

          Graders::List.pass?(spec, value)
        else
          outcome = Graders::Fields.outcome(spec, value)
          outcome == 'unjudged' ? nil : Graders::Fields::RIGHT.include?(outcome)
        end
      end

      # A twin row's score label is {"text": n, "twin": n}: both in the band, as the grader needs, and
      # within `max_gap` when the gold has one.
      def scored_within?(spec, value, twin: false)
        scores = value.is_a?(Hash) ? value : { 'text' => value }
        text = Matchers.number(scores['text'])
        return Graders::Band.within?(spec, text) unless twin || spec.key?('max_gap')

        other = Matchers.number(scores['twin'])
        return false unless Graders::Band.within?(spec, text) && Graders::Band.within?(spec, other)

        !spec.key?('max_gap') || Graders::Band.gap(text, other).abs <= spec['max_gap']
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Eval
    # The confusion matrices of a report. Each method takes graded rows (Results::Row) and returns a
    # Report section, or an empty one when it doesn't apply.
    module Matrices
      NONE = '(none)'
      OTHER = '(other)' # in parentheses, like NONE, so it never collides with a category named "other"
      MAX_COLUMNS = 8 # a long tail of predicted values goes into OTHER
      LABEL = 30 # gold and predicted labels are cut the same way, so a right answer stays on the diagonal
      OUTCOMES = %w[correct wrong_value omission invention correct_abstention unjudged].freeze

      module_function

      # Baseline pass/fail x now pass/fail on the paired cases: the table behind the McNemar test.
      def baseline(paired)
        count = ->(base, now) { paired.count { |cur, b| b.pass? == base && cur.pass? == now } }
        Report.new.heading('Baseline vs now').table(
          ['', 'now pass', 'now fail'],
          [['baseline pass', count.call(true, true), "#{count.call(true, false)} broke"],
           ['baseline fail', "#{count.call(false, true)} fixed", count.call(false, false)]]
        )
      end

      # Gold present/absent x answered/left empty, overall, then each field's outcomes.
      def field_outcomes(rows)
        outcomes = rows.filter_map { |r| fields(r) }
        return Report.new if outcomes.empty?

        all = Hash.new(0).merge(outcomes.flat_map(&:values).tally)
        answered = "#{all['correct']} correct · #{all['wrong_value']} wrong"
        answered += " · #{all['unjudged']} unjudged" if all['unjudged'].positive?
        report = Report.new.heading('Field outcomes').table(
          ['', 'answered', 'left empty'],
          [['gold present', answered, "#{all['omission']} omission"],
           ['gold absent', "#{all['invention']} invention", "#{all['correct_abstention']} correct abstention"]]
        )
        by_field = outcomes.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |fields, acc|
          fields.each { |name, outcome| acc[name][outcome] += 1 }
        end
        shown = OUTCOMES.select { |o| by_field.values.any? { |t| t[o].positive? } }
        table = by_field.sort.map { |name, tally| [name, *shown.map { |o| dot(tally[o]) }] }
        report.blank.table(['field', *shown.map { |o| o.tr('_', ' ') }], table)
      end

      # Gold value x predicted value for each field whose gold is a category (an `eq` or `one_of` on text,
      # or absent), with its accuracy and the pairs most often confused.
      def categorical(rows)
        cells = Hash.new { |h, k| h[k] = [] } # field => [[gold label, predicted label, outcome]]
        rows.each do |row|
          next unless (outcomes = fields(row))

          data = output_hash(row)
          row.item.gold.fetch('fields', {}).each do |name, spec|
            # A gold that is not a label (a regex, a number) stays in, so `categorical?` rejects the field
            # instead of drawing a matrix over the cases that happen to be labels.
            cells[name] << [spec.is_a?(Hash) ? gold_label(spec) : nil, predicted_label(data[name]), outcomes[name]]
          end
        end
        categories = cells.select { |_name, c| categorical?(c.map(&:first)) }
        categories.sort.each_with_object(Report.new) { |(name, c), report| report.concat(field_matrix(name, c)) }
      end

      # Gold band x where the score landed: below, inside or above the band (or no score at all).
      # Only a [lo, hi] band of numbers: a custom grader's details may use the key for anything.
      def bands(rows)
        scored = rows.select { |r| band?(r.grade.detail['band']) }
        return Report.new if scored.empty?

        table = scored.group_by { |r| r.grade.detail['band'] }.sort_by { |band, _| band }.map do |band, band_rows|
          where = band_rows.map { |r| bucket(r.grade.detail['score'], band) }.tally
          [band.inspect, *%w[below inside above no_score].map { |k| dot(where[k].to_i) }]
        end
        Report.new.heading('Score bands').table(['gold band', 'below', 'inside', 'above', 'no score'], table)
      end

      def field_matrix(name, cells)
        golds = cells.map(&:first).tally.sort_by { |label, n| [-n, label] }.map(&:first)
        predicted = cells.map { |c| c[1] }.tally.sort_by { |label, n| [-n, label] }.map(&:first)
        columns = (golds.flat_map { |g| g.split(' | ') } + predicted).uniq
        columns = columns.first(MAX_COLUMNS) + [OTHER] if columns.size > MAX_COLUMNS + 1
        column = ->(label) { columns.include?(label) ? label : OTHER }
        counts = cells.group_by(&:first).transform_values { |c| c.map { |cell| column.call(cell[1]) }.tally }
        right = cells.count { |c| Graders::Fields::RIGHT.include?(c[2]) }
        confused = cells.reject { |c| Graders::Fields::RIGHT.include?(c[2]) }.map { |c| "#{c[0]} → #{c[1]}" }.tally
                        .sort_by { |pair, n| [-n, pair] }.first(3).map { |pair, n| "#{pair} (#{n})" }
        summary = "accuracy #{(100.0 * right / cells.size).round}% (#{right}/#{cells.size})"
        summary += " · most confused: #{confused.join(', ')}" if confused.any?
        Report.new.heading("#{name}: gold ↓ · predicted →")
              .table(['', *columns], golds.map { |g| [g, *columns.map { |col| dot(counts[g][col].to_i) }] })
              .line(summary)
      end

      # A field is a category when every gold is a fixed label and the labels repeat: an id or a name
      # that is different in every case is not a category, even when written as `eq`.
      def categorical?(labels)
        return false if labels.empty? || !labels.all?

        named = labels - [NONE]
        named.any? && named.uniq.size <= 12 && named.uniq.size < named.size && labels.uniq.size > 1
      end

      def gold_label(spec)
        return NONE if spec['present'] == false

        values = spec['check'] == 'eq' ? [spec['value']] : spec['value']
        return unless %w[eq one_of].include?(spec['check']) && values.is_a?(Array) && values.all?(String)

        values.map { |v| label(v) }.join(' | ')
      end

      def predicted_label(value)
        Matchers.absent?(value) ? NONE : label(value)
      end

      def label(value)
        Matchers.normalize(value)[0, LABEL]
      end

      # The grade's field outcomes, when they are the fields grader's { name => outcome } shape.
      def fields(row)
        outcomes = row.grade.detail['fields']
        outcomes if outcomes.is_a?(Hash)
      end

      def band?(band)
        band.is_a?(Array) && band.size == 2 && band.all?(Numeric)
      end

      def output_hash(row)
        data = row.record&.dig('output', 'data')
        data.is_a?(Hash) ? data : { 'value' => data }
      end

      # Zero shows as a dot, so the cells that matter stand out.
      def dot(count) = count.zero? ? '·' : count

      def bucket(score, band)
        return 'no_score' unless score.is_a?(Numeric)
        return 'below' if score < band[0]
        return 'above' if score > band[1]

        'inside'
      end
    end
  end
end

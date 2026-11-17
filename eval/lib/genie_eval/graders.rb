# frozen_string_literal: true

module GenieEval
  # One grader per module. Each takes the gold record's `gold` hash and an output record
  # and returns a Grade. A crashed or empty call always fails with outcome "error".
  module Graders
    Grade = Struct.new(:pass, :detail, keyword_init: true)

    module_function

    def for(cell_id)
      name = Store.cell(cell_id).fetch('grader')
      const_get(name.capitalize)
    end

    def grade(cell_id, gold, record)
      return Grade.new(pass: false, detail: { 'outcome' => 'missing' }) if record.nil?
      return Grade.new(pass: false, detail: { 'outcome' => 'error', 'error' => record['error'] }) if record['error']

      grade = self.for(cell_id).grade(gold, record)
      return grade unless gold['require_reasoning'] && missing_reasoning?(record)

      Grade.new(pass: false, detail: grade.detail.merge('reasoning' => 'missing'))
    end

    def missing_reasoning?(record)
      outputs = record['orders'] ? record['orders'].values : [record['output']]
      outputs.any? { |output| Matchers.absent?(output&.dig('reasoning')) }
    end

    module Extractor
      RIGHT = %w[correct correct_abstention].freeze

      module_function

      def grade(gold, record)
        data = record.dig('output', 'data')
        data = {} unless data.is_a?(Hash)
        fields = gold.fetch('fields').to_h { |name, spec| [name, outcome(spec, data[name])] }
        Grade.new(pass: fields.values.all? { |o| RIGHT.include?(o) }, detail: { 'fields' => fields })
      end

      def outcome(spec, value)
        absent = Matchers.absent?(value)
        if spec['present'] == false
          absent ? 'correct_abstention' : 'invention'
        elsif absent && spec['present'] == 'optional' # a human accepted both "not stated" and the value
          'correct_abstention'
        elsif absent
          'omission'
        elsif Matchers.check?(spec, value)
          'correct'
        else
          judged(spec, value)
        end
      end

      # A field marked `judge: true` goes to the LLM judge when the deterministic check fails.
      def judged(spec, value)
        return 'wrong_value' unless spec['judge']

        reference = spec['reference'] || spec['value'].to_s # `reference`: the human-readable gold, when `value` is a check operand
        verdict = Judge.current.verdict(question: spec.fetch('question'), reference:,
                                        candidate: value.is_a?(String) ? value : JSON.generate(value))
        return 'unjudged' if verdict.nil?

        verdict.match ? 'correct' : 'wrong_value'
      end
    end

    module Comparator
      module_function

      def grade(gold, record)
        ab = record.dig('orders', 'ab', 'winner')
        ba = record.dig('orders', 'ba', 'winner')
        consistent = !ab.nil? && ab == ba
        winner = gold.fetch('winner')
        pass = winner == 'either' ? !ab.nil? && !ba.nil? : ab == winner && ba == winner
        Grade.new(pass:, detail: { 'ab' => ab, 'ba' => ba, 'consistent' => consistent })
      end
    end

    module Lister
      module_function

      def grade(gold, record)
        items = Array(record.dig('output', 'data')).map { |item| Matchers.normalize(item) }
        results = gold.fetch('checks').map { |check| [check['type'], passes?(check, items)] }
        Grade.new(pass: results.all?(&:last), detail: { 'checks' => results.to_h, 'items' => items.size })
      end

      def passes?(check, items)
        hit = ->(item) { Matchers.contains_any?(item, check['any_of']) }
        case check['type']
        when 'top_k_any' then items.first(check.fetch('k')).any?(&hit)
        when 'bottom_k_none' then items.last(check.fetch('k')).none?(&hit)
        when 'min_groups' then min_groups?(check, items)
        when 'any_item' then items.any?(&hit)
        when 'no_item' then items.none?(&hit)
        when 'min_items' then items.size >= check.fetch('n')
        else raise Error, "unknown lister check #{check['type'].inspect}"
        end
      end

      # At least `min` of the `groups` (each a list of synonyms) appear somewhere in the list.
      def min_groups?(check, items)
        hits = check.fetch('groups').count { |group| items.any? { |item| Matchers.contains_any?(item, group) } }
        hits >= check.fetch('min')
      end
    end

    module Scorer
      module_function

      def grade(gold, record)
        score = Matchers.number(record.dig('output', 'data'))
        lo, hi = gold.fetch('band')
        Grade.new(pass: !score.nil? && score.between?(lo, hi), detail: { 'score' => score, 'band' => [lo, hi] })
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Grades one output record against a row's gold. A crashed or missing call always fails.
    #
    #   fields  {"fields": {"intent": {"present": true, "check": "eq", "value": "refund"}, ...}}
    #   band    {"band": [60, 100]}                        a number (or a Hash's "score") in the band
    #   list    {"checks": [{"type": "top_k_any", "k": 2, "any_of": ["apple"]}, ...]}
    #   rubric  {"rubric": "Polite, answers the question asked, ...", "band": [70, 100]}
    #   winner  {"winner": "a"}                              "a", "b" or "either"; both orders must agree
    #
    # or the eval's own block. A twin row (see Selection::Item#twin) passes when both its outputs pass;
    # a band or rubric gold may also limit how far apart the two scores are (`max_gap`). A gold with
    # `require_reasoning: true` fails an output that came back without its reasoning.
    module Graders
      Grade = Struct.new(:pass, :detail, keyword_init: true) do
        # Waiting for a judge verdict that isn't cached yet (a rubric row, or a `judge: true` field), on
        # either output of a twin row.
        def unjudged?
          fields = detail['fields']
          twin = detail['twin']
          detail['outcome'] == 'unjudged' || (fields.is_a?(Hash) && fields.value?('unjudged')) ||
            (twin.is_a?(Hash) && self.class.new(pass: false, detail: twin).unjudged?)
        end
      end

      module_function

      def grade(definition, gold, record)
        return Grade.new(pass: false, detail: { 'outcome' => 'missing' }) if record.nil?
        return Grade.new(pass: false, detail: { 'outcome' => 'error', 'error' => record['error'] }) if record['error']

        grade = record.key?('twin') ? twin(definition, gold, record) : one(definition, gold, record, 'output')
        return grade unless gold['require_reasoning'] && missing_reasoning?(record)

        Grade.new(pass: false, detail: grade.detail.merge('reasoning' => 'missing'))
      end

      def one(definition, gold, record, key)
        output = record.dig(key, 'data')
        return custom(definition, output, gold, record) if definition.custom_grader?

        case definition.grader
        when 'fields' then Fields.grade(gold, output)
        when 'band' then Band.grade(gold, output)
        when 'list' then List.grade(gold, output)
        when 'rubric' then Rubric.grade(gold, output)
        when 'winner' then Winner.grade(gold, output)
        else raise Error, "#{definition.name}: unknown grader #{definition.grader.inspect}"
        end
      end

      # Both outputs must pass. For scores, `gap` is twin minus text, so its sign shows which way the
      # change that should not matter moved the score; `max_gap` caps its size.
      def twin(definition, gold, record)
        first = one(definition, gold, record, 'output')
        second = one(definition, gold, record, 'twin')
        detail = first.detail.merge('twin' => second.detail)
        pass = first.pass && second.pass
        if first.detail['score'].is_a?(Numeric) || second.detail['score'].is_a?(Numeric)
          gap = Band.gap(first.detail['score'], second.detail['score'])
          detail.merge!('twin_score' => second.detail['score'], 'gap' => gap)
          pass &&= !gap.nil? && gap.abs <= gold['max_gap'] if gold.key?('max_gap')
        end
        Grade.new(pass:, detail:)
      end

      def missing_reasoning?(record)
        outputs = [record['output'], record['twin']].compact
        outputs.any? { |output| Matchers.absent?(output['reasoning']) }
      end

      # A custom grader returns true/false, or a Hash with "pass" (or :pass) and any details to show.
      def custom(definition, output, gold, record)
        result = definition.grader.call(output, gold, record)
        return Grade.new(pass: result == true, detail: {}) unless result.is_a?(Hash)

        detail = result.transform_keys(&:to_s)
        Grade.new(pass: detail.delete('pass') == true, detail:)
      end

      # Text the judge reads: strings as they are, anything else as JSON.
      def text(value)
        value.is_a?(String) ? value : JSON.generate(value)
      end

      # Each field gets one of five outcomes; the case passes when every field is right.
      module Fields
        RIGHT = %w[correct correct_abstention].freeze

        module_function

        def grade(gold, output)
          data = output.is_a?(Hash) ? output : { 'value' => output }
          fields = gold.fetch('fields').to_h { |name, spec| [name, outcome(spec, data[name])] }
          Grade.new(pass: fields.values.all? { |o| RIGHT.include?(o) }, detail: { 'fields' => fields })
        end

        def outcome(spec, value)
          absent = Matchers.absent?(value)
          if spec['present'] == false
            absent ? 'correct_abstention' : 'invention'
          elsif absent && spec['present'] == 'optional'
            'correct_abstention'
          elsif absent
            'omission'
          elsif Matchers.check?(spec, value)
            'correct'
          else
            judged(spec, value)
          end
        end

        # A field marked `judge: true` goes to the LLM judge when its deterministic check fails.
        def judged(spec, value)
          return 'wrong_value' unless spec['judge']

          reference = spec['reference'] || Graders.text(spec['value'])
          verdict = Judge.current.equivalent(question: spec.fetch('question'), reference:,
                                             candidate: Graders.text(value))
          return 'unjudged' if verdict.nil?

          verdict.match ? 'correct' : 'wrong_value'
        end
      end

      module Band
        module_function

        def grade(gold, output)
          score = Matchers.number(output.is_a?(Hash) ? output['score'] : output)
          Grade.new(pass: within?(gold, score), detail: { 'score' => score, 'band' => gold.fetch('band') })
        end

        def within?(gold, score)
          lo, hi = gold.fetch('band')
          !score.nil? && score.between?(lo, hi)
        end

        # Rounded as the report shows it, so a gap shown as 10.0 passes a max_gap of 10.
        def gap(score, twin)
          score && twin && (twin - score).round(1)
        end
      end

      # A free-text answer, scored 0-100 by the judge against the row's rubric.
      module Rubric
        module_function

        def grade(gold, output)
          verdict = Judge.current.rubric(rubric: gold.fetch('rubric'), candidate: Graders.text(output))
          return Grade.new(pass: false, detail: { 'outcome' => 'unjudged' }) if verdict.nil?

          score = Matchers.number(verdict.score)
          Grade.new(pass: Band.within?(gold, score),
                    detail: { 'score' => score, 'band' => gold.fetch('band'),
                              'why' => verdict.reason })
        end
      end

      # A pick between two sides. The output is the side ("a", "b" or "either", or nil for no pick), or a
      # Hash of the side picked in each order, {"ab": ..., "ba": ...}, already mapped back to the row's own
      # a/b. With both orders, both must give the gold winner, and `consistent` says whether they agreed.
      module Winner
        SIDES = %w[a b either].freeze

        module_function

        def grade(gold, output)
          winner = gold.fetch('winner')
          picks = output.is_a?(Hash) ? output.values_at('ab', 'ba') : [output]
          picks = picks.map { |p| SIDES.include?(p) ? p : nil }
          pass = winner == 'either' ? picks.none?(&:nil?) : picks.all?(winner)
          detail = output.is_a?(Hash) ? { 'ab' => picks[0], 'ba' => picks[1] } : { 'winner' => picks[0] }
          detail['consistent'] = !picks[0].nil? && picks.uniq.size == 1 if picks.size == 2
          Grade.new(pass:, detail:)
        end
      end

      module List
        CHECKS = { 'top_k_any' => %w[k any_of], 'bottom_k_none' => %w[k any_of], 'min_groups' => %w[min groups],
                   'any_item' => %w[any_of], 'no_item' => %w[any_of], 'min_items' => %w[n],
                   'max_items' => %w[n] }.freeze

        module_function

        def grade(gold, output)
          items = items(output)
          results = results(gold, items)
          Grade.new(pass: results.all?(&:last), detail: { 'checks' => named(results), 'items' => items.size })
        end

        def pass?(gold, list) = results(gold, items(list)).all?(&:last)

        def items(list) = Array(list).map { |item| Matchers.normalize(item) }

        def results(gold, items)
          gold.fetch('checks').map { |check| [check['type'], passes?(check, items)] }
        end

        # { type => pass }, a repeated type numbered ("any_item#2") so one result cannot hide another.
        def named(results)
          count = Hash.new(0)
          results.to_h { |type, pass| [(count[type] += 1) > 1 ? "#{type}##{count[type]}" : type, pass] }
        end

        # A term matches where a word starts: "bee" matches "bees", "rain" matches "rainy", but "rain"
        # does not match "train".
        def pattern(terms)
          /(?<![[:alnum:]])(?:#{Regexp.union(Array(terms).map { |term| Matchers.normalize(term) }).source})/
        end

        def passes?(check, items)
          pattern = pattern(check['any_of'])
          hit = ->(item) { item.match?(pattern) }
          case check['type']
          when 'top_k_any' then items.first(check.fetch('k')).any?(&hit)
          when 'bottom_k_none' then items.last(check.fetch('k')).none?(&hit)
          when 'min_groups' then min_groups?(check, items)
          when 'any_item' then items.any?(&hit)
          when 'no_item' then items.none?(&hit)
          when 'min_items' then items.size >= check.fetch('n')
          when 'max_items' then items.size <= check.fetch('n')
          else raise Error, "unknown list check #{check['type'].inspect}"
          end
        end

        # At least `min` of the `groups` (each a list of synonyms) are filled, each by a different item.
        def min_groups?(check, items)
          fits = check.fetch('groups').map do |group|
            pattern = pattern(group)
            items.each_index.select { |i| items[i].match?(pattern) }
          end
          owner = {}
          fits.each_index.count { |group| fill(group, fits, owner, Set.new) } >= check.fetch('min')
        end

        # Gives `group` an item, moving another group to a different item when that frees one up.
        def fill(group, fits, owner, seen)
          fits[group].any? do |item|
            next false unless seen.add?(item)
            next false if owner.key?(item) && !fill(owner[item], fits, owner, seen)

            owner[item] = group
            true
          end
        end
      end
    end
  end
end

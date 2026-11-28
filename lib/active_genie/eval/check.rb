# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Free checks, no model calls: evals/config.yml, each eval.rb, and the integrity of every
    # datasets.jsonl and gold.jsonl. A typo in a gold would not fail loudly at run time: it would
    # silently grade wrong.
    class Check
      ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/
      ID = /\A[a-z0-9_]+\z/

      attr_reader :errors, :warnings

      def initialize
        @errors = []
        @warnings = []
      end

      def run(only: nil)
        check_config
        definitions = Eval.load!.values
        if only
          definitions = definitions.select { |d| d.name == only.to_s }
          @errors << "no eval #{only} in evals/ (evals: #{Eval.definitions.keys.sort.join(', ')})" if definitions.empty?
        elsif definitions.empty?
          @warnings << 'no evals yet: create one with `rake "active_genie:eval:new[name]"`'
        end
        definitions.each { |definition| check_eval(definition) }
        self
      # An eval.rb that raises anything at load time (a typo, a missing require) is reported, not a crash.
      rescue StandardError, ScriptError => e
        @errors << "#{e.class}: #{e.message}"
        self
      end

      def ok?
        errors.empty?
      end

      def report
        [*errors.map { |e| "ERROR #{e}" }, *warnings.map { |w| "WARN  #{w}" },
         ok? ? 'check passed' : "check failed: #{errors.size} error(s)"].join("\n")
      end

      private

      def check_config
        config = Eval.config
        concurrency = config['concurrency']
        unless concurrency.nil? || (concurrency.is_a?(Integer) && concurrency.positive?)
          @errors << "evals/config.yml: concurrency must be a positive integer, not #{concurrency.inspect}"
        end
        return if config['dev']

        @warnings << 'evals/config.yml has no dev: { provider, model }; runs use your app\'s own defaults'
      end

      # Rubric rows and `judge: true` fields need the judge; without one a paid run grades nothing.
      def check_judge(definition)
        return if definition.custom_grader?

        judge = Eval.config['judge']
        return if judge.is_a?(Hash) && judge['provider'] && judge['model']

        judged = definition.grader == 'rubric' || Store.rows(definition).any? do |row|
          fields = row.dig('gold', 'fields') if row['gold'].is_a?(Hash)
          fields.is_a?(Hash) && fields.values.any? { |spec| spec.is_a?(Hash) && spec['judge'] }
        end
        return unless judged

        @errors << "#{definition.name}: grades with the judge, but evals/config.yml has no judge: { provider, model }"
      end

      def check_eval(definition)
        name = definition.name
        @errors << "#{name}: eval.rb has no `call` block or variants" unless definition.runnable?
        if definition.subject && definition.variants.any?
          @warnings << "#{name}: eval.rb has both a `call` block and variants; only the variants run"
        end
        unless definition.custom_grader? || Definition::GRADERS.include?(definition.grader)
          @errors << "#{name}: grader must be one of #{Definition::GRADERS.join(', ')} or a block, not #{definition.grader.inspect}"
        end
        definition.watch.each do |glob|
          @warnings << "#{name}: watch #{glob.inspect} matches no file" if Dir.glob(File.join(Eval.app_root, glob)).empty?
        end
        check_rows(definition)
        check_judge(definition)
      end

      def check_rows(definition)
        name = definition.name
        rows = Store.rows(definition)
        @warnings << "#{name}: no cases yet in evals/#{name}/datasets.jsonl" if rows.empty?
        ids = rows.map { |r| r['id'] }
        ids.tally.each { |id, n| @errors << "#{name}/#{id}: id appears #{n} times in datasets.jsonl" if n > 1 }
        rows.each { |row| check_row(definition, row, "#{name}/#{row['id']}") }
        check_labels(definition, ids)
      end

      def check_row(definition, row, where)
        @errors << "#{where}: id must be snake_case" unless row['id'].to_s.match?(ID)
        @errors << "#{where}: pool must be dev or test" unless %w[dev test].include?(row['pool'])
        unless row['status'].nil? || Store::STATUSES.include?(row['status'])
          @errors << "#{where}: status must be one of #{Store::STATUSES.join(', ')} (or absent)"
        end
        if row.key?('on_disagreement') && row['on_disagreement'] != 'drop'
          @errors << "#{where}: on_disagreement takes only \"drop\""
        end
        @errors << "#{where}: needs an input" unless row.key?('input')
        return @errors << "#{where}: needs a gold" unless row['gold'].is_a?(Hash)

        twin = twin_problem(definition, row)
        @errors << "#{where}: #{twin}" if twin
        return if definition.custom_grader?

        problem = case definition.grader
                  when 'fields' then fields_problem(row['gold'])
                  when 'band' then band_problem(row['gold'])
                  when 'list' then list_problem(row['gold'])
                  when 'rubric' then rubric_problem(row['gold'])
                  when 'winner' then winner_problem(row['gold'])
                  end
        @errors << "#{where}: #{problem}" if problem
      end

      # A twin is a Hash merged over the input that changes it; `max_gap` (a number) only means
      # something for a twin scored by band or rubric.
      def twin_problem(definition, row)
        twin = row['twin']
        gap = row['gold'].key?('max_gap')
        if twin.nil?
          return gap ? 'max_gap needs a twin: the same input with one change that should not matter' : nil
        end
        return 'twin must be an object merged over the input, e.g. {"text": "..."}' unless twin.is_a?(Hash) && twin.any?
        # Merged at run time: on any other input the twin call would fail after the first one was paid.
        return 'a twin needs an object input to merge over' unless row['input'].is_a?(Hash)
        return 'twin must change the input' if row['input'].merge(twin) == row['input']
        return unless gap

        return 'max_gap only applies to band and rubric graders' unless %w[band rubric].include?(definition.grader)

        'max_gap must be a number >= 0' unless row['gold']['max_gap'].is_a?(Numeric) && row['gold']['max_gap'] >= 0
      end

      def winner_problem(gold)
        "winner must be one of #{Graders::Winner::SIDES.join(', ')}" unless Graders::Winner::SIDES.include?(gold['winner'])
      end

      def check_labels(definition, ids)
        Store.labels(definition).each do |label|
          where = "#{definition.name}/gold.jsonl"
          @errors << "#{where}: #{label['id']} is not a row of datasets.jsonl" unless ids.include?(label['id'])
          @errors << "#{where}/#{label['id']}: pass must be a or b" unless %w[a b].include?(label['pass'])
        end
      end

      def fields_problem(gold)
        fields = gold['fields']
        return 'a fields gold needs a non-empty "fields" hash' unless fields.is_a?(Hash) && fields.any?

        unknown = fields.reject { |_n, spec| spec.is_a?(Hash) && (spec['present'] == false || Matchers::CHECKS.include?(spec['check'])) }
        return "unknown or missing check for #{unknown.keys.join(', ')} (checks: #{Matchers::CHECKS.join(', ')})" if unknown.any?

        odd = fields.reject { |_n, spec| [true, false, 'optional'].include?(spec['present']) }
        return "present must be true, false or \"optional\" for #{odd.keys.join(', ')}" if odd.any?

        malformed = fields.reject { |_n, spec| spec['present'] == false || value_problem(spec).nil? }
        if malformed.any?
          return malformed.map { |name, spec| "#{name}: #{spec['check']} #{value_problem(spec)}" }.join('; ')
        end

        dates = fields.select { |_n, spec| spec['check'] == 'date' && !spec['value'].to_s.match?(ISO_DATE) }
        return "date checks need an ISO value (YYYY-MM-DD) for #{dates.keys.join(', ')}" if dates.any?

        unasked = fields.select { |_n, spec| spec['judge'] && spec['question'].to_s.strip.empty? }
        "judge fields need a question: #{unasked.keys.join(', ')}" if unasked.any?
      end

      # A check's `value` the matcher can't use would crash the report after a paid run, or (a `between`
      # without [lo, hi]) grade every output wrong.
      def value_problem(spec)
        value = spec['value']
        case spec['check']
        when 'regex' then regex_problem(value)
        when 'contains_any', 'contains_all' then 'needs a list of texts' unless terms?(Array(value))
        when 'gte', 'lte' then 'needs a number' unless value.is_a?(Numeric)
        when 'between' then 'needs [lo, hi] numbers with lo <= hi' unless band?(value)
        when 'near'
          delta = spec['delta']
          'needs a number and a "delta" >= 0' unless value.is_a?(Numeric) && delta.is_a?(Numeric) && delta >= 0
        end
      end

      def band?(value)
        value.is_a?(Array) && value.size == 2 && value.all?(Numeric) && value[0] <= value[1]
      end

      def regex_problem(value)
        return 'needs a pattern text' unless value.is_a?(String)

        Regexp.new(value)
        nil
      rescue RegexpError => e
        "is not a valid pattern (#{e.message})"
      end

      def band_problem(gold)
        lo, hi = gold['band']
        'band must be [lo, hi] with lo <= hi' unless [lo, hi].all?(Numeric) && lo <= hi
      end

      def rubric_problem(gold)
        return 'a rubric gold needs a "rubric" text' unless gold['rubric'].is_a?(String) && !gold['rubric'].strip.empty?

        lo, hi = gold['band']
        return if [lo, hi].all?(Numeric) && lo <= hi && lo >= 0 && hi <= 100

        'a rubric gold needs a band [lo, hi] within 0..100'
      end

      def list_problem(gold)
        checks = gold['checks']
        return 'a list gold needs a non-empty "checks" array' unless checks.is_a?(Array) && checks.any?
        return 'each list check must be an object with a type' unless checks.all? { |c| c.is_a?(Hash) && c['type'] }

        unknown = checks.map { |c| c['type'] } - Graders::List::CHECKS.keys
        return "unknown list checks #{unknown.join(', ')}" if unknown.any?

        checks.filter_map { |c| list_check_problem(c) }.first || list_size_problem(checks)
      end

      # A min_items above a max_items fails every output, so the row could never pass.
      def list_size_problem(checks)
        least = checks.filter_map { |c| c['n'] if c['type'] == 'min_items' }.max
        most = checks.filter_map { |c| c['n'] if c['type'] == 'max_items' }.min
        "min_items #{least} is more than max_items #{most}" if least && most && least > most
      end

      # A check takes exactly its settings: a misspelled key would otherwise be ignored by the grader.
      def list_check_problem(check)
        type = check['type']
        settings = Graders::List::CHECKS.fetch(type)
        odd = check.keys - ['type'] - settings
        return "#{type} takes #{settings.join(' and ')}, not #{odd.join(', ')}" if odd.any?

        bad = settings.reject do |key|
          value = check[key]
          case key
          when 'k', 'min', 'n' then value.is_a?(Integer) && value.positive?
          when 'any_of' then terms?(value)
          when 'groups' then value.is_a?(Array) && value.any? && value.all? { |g| terms?(g) }
          end
        end
        return "#{type} needs a well-formed #{bad.join(' and ')}" if bad.any?
        return unless type == 'min_groups' && check['min'] > check['groups'].size

        "min_groups min #{check['min']} is more than its #{check['groups'].size} groups"
      end

      def terms?(value)
        value.is_a?(Array) && value.any? && value.all? { |t| t.is_a?(String) && !t.strip.empty? }
      end
    end
  end
end

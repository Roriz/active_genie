# frozen_string_literal: true

module GenieEval
  # Free checks, no model calls: data integrity of cases/gold/pools, and a lint of the prompt
  # and function-schema files in lib/ (empty files, mojibake, broken JSON, what changed vs main).
  class Check
    REQUIRED_INPUT = {
      'extractor' => %w[text schema], 'comparator' => %w[player_a player_b criteria],
      'lister.with_feud' => %w[theme], 'lister.with_juries' => %w[text criteria], 'scorer' => %w[text criteria]
    }.freeze
    # Each lister check type with the settings it takes, all required.
    LISTER_CHECKS = { 'top_k_any' => %w[k any_of], 'bottom_k_none' => %w[k any_of], 'min_groups' => %w[min groups],
                      'any_item' => %w[any_of], 'no_item' => %w[any_of], 'min_items' => %w[n] }.freeze
    MOJIBAKE = /Ã.|â€|ï»¿|�/
    ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/

    attr_reader :errors, :warnings, :infos

    def initialize
      @errors = []
      @warnings = []
      @infos = []
    end

    def run
      check_data
      check_prompts
      self
    end

    def ok?
      errors.empty?
    end

    def report
      [*errors.map { |e| "ERROR #{e}" }, *warnings.map { |w| "WARN  #{w}" }, *infos.map { |i| "INFO  #{i}" },
       ok? ? 'check passed' : "check failed: #{errors.size} error(s)"].join("\n")
    end

    private

    def check_data
      pools = Store.pools
      pool_keys = pools.map { |p| [p['cell'], p['id']] }
      @errors << 'pools.jsonl has duplicate entries' if pool_keys.uniq.size != pool_keys.size
      known = Store.cells.flat_map { |cell| check_cell(cell, pool_keys) }
      (pool_keys - known).each { |cell, id| @errors << "pools.jsonl: #{cell}/#{id} has no case" }
      pools.each { |p| check_pool_row(p) }
    end

    def check_cell(cell, pool_keys)
      id = cell['id']
      @errors << "#{id}: no executor" unless Executor::CALLS.key?(id)
      cases = Store.cases(id)
      gold = Store.gold(id)
      ids = cases.map { |c| c['id'] }
      @errors << "#{id}: duplicate case ids" if ids.uniq.size != ids.size
      (gold.keys - ids).each { |orphan| @errors << "#{id}/#{orphan}: gold without a case" }
      cases.each do |kase|
        where = "#{id}/#{kase['id']}"
        @errors << "#{where}: case says cell #{kase['cell']}" if kase['cell'] != id
        check_input(id, kase['input'] || {}, where)
        @errors << "#{where}: no pool entry" unless pool_keys.include?([id, kase['id']])
        if gold[kase['id']]
          check_gold(cell['grader'], gold[kase['id']]['gold'] || {}, where, kase['input'] || {})
        else
          @errors << "#{where}: no gold"
        end
      end
      ids.map { |case_id| [id, case_id] }
    end

    def check_input(cell_id, input, where)
      required = REQUIRED_INPUT[cell_id] || REQUIRED_INPUT[cell_id.split('.').first] || []
      missing = required.reject { |k| input.key?(k) }
      @errors << "#{where}: input missing #{missing.join(', ')}" if missing.any?
      # The executor scores any `twin` it is given, but only the scorer grades one.
      @errors << "#{where}: only scorer cases take a twin" if input.key?('twin') && !cell_id.start_with?('scorer.')
    end

    def check_gold(grader, gold, where, input)
      problem = case grader
                when 'extractor' then extractor_problem(gold)
                when 'comparator'
                  'winner must be a, b or either' unless Graders::Comparator::WINNERS.include?(gold['winner'])
                when 'lister' then lister_problem(gold)
                when 'scorer' then scorer_problem(gold, input)
                end
      @errors << "#{where}: #{problem}" if problem
    end

    def extractor_problem(gold)
      return 'extractor gold needs a non-empty fields hash' unless gold['fields'].is_a?(Hash) && gold['fields'].any?

      bad = gold['fields'].reject do |_name, spec|
        spec['present'] == false || Matchers::CHECKS.include?(spec['check'])
      end
      return "unknown or missing check for #{bad.keys.join(', ')}" if bad.any?

      field_problem(gold['fields'])
    end

    # A typo here would not fail loudly: it would silently grade every output wrong.
    def field_problem(fields)
      odd = fields.reject { |_name, spec| [true, false, 'optional'].include?(spec['present']) }
      return "present must be true, false or \"optional\" for #{odd.keys.join(', ')}" if odd.any?

      dates = fields.select { |_name, spec| spec['check'] == 'date' && !spec['value'].to_s.match?(ISO_DATE) }
      return "date checks need an ISO value (YYYY-MM-DD) for #{dates.keys.join(', ')}" if dates.any?

      unasked = fields.select { |_name, spec| spec['judge'] && spec['question'].to_s.strip.empty? }
      "judge fields need a question: #{unasked.keys.join(', ')}" if unasked.any?
    end

    def lister_problem(gold)
      checks = gold['checks']
      return 'lister gold needs a non-empty checks array' unless checks.is_a?(Array) && checks.any?

      unknown = checks.map { |c| c['type'] } - LISTER_CHECKS.keys
      return "unknown lister checks #{unknown.join(', ')}" if unknown.any?

      checks.filter_map { |c| lister_check_problem(c) }.first
    end

    # A check takes exactly its settings: a misspelled key would otherwise be ignored by the grader.
    def lister_check_problem(check)
      type = check['type']
      settings = LISTER_CHECKS.fetch(type)
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

    def scorer_problem(gold, input)
      lo, hi = gold['band']
      return 'band must be [lo, hi] within 0..100' unless [lo, hi].all?(Numeric) && lo <= hi && lo >= 0 && hi <= 100
      return 'a case has a twin exactly when its gold has a max_gap' if input.key?('twin') != gold.key?('max_gap')
      return unless input.key?('twin')

      twin = input['twin']
      unless twin.is_a?(String) && !twin.strip.empty? && twin != input['text']
        return 'twin must be a non-empty text that differs from text'
      end

      gap = gold['max_gap']
      'max_gap must be a number >= 0' unless gap.is_a?(Numeric) && gap >= 0
    end

    def check_pool_row(row)
      where = "pools.jsonl #{row['cell']}/#{row['id']}"
      @errors << "#{where}: pool must be dev or test" unless %w[dev test].include?(row['pool'])
      @errors << "#{where}: role must be null, hard or canary" unless [nil, 'hard', 'canary'].include?(row['role'])
    end

    def check_prompts
      Dir.glob(File.join(REPO, 'lib', 'active_genie', '**', '*.prompt.md')).each { |file| check_prompt(file) }
      Dir.glob(File.join(REPO, 'lib', 'active_genie', '{comparator,extractor,lister,scorer}', '*.json')).each do |file|
        JSON.parse(File.read(file))
      rescue JSON::ParserError => e
        @errors << "#{relative(file)}: invalid JSON (#{e.message.lines.first.strip})"
      end
      changed = changed_vs_main
      @infos << (changed.empty? ? 'lib/ matches main: a run reproduces the baseline' : "lib/ changed vs main: #{changed.join(', ')}")
    end

    def check_prompt(file)
      text = File.read(file, encoding: 'UTF-8')
      @errors << "#{relative(file)}: empty prompt" if text.strip.empty?
      @errors << "#{relative(file)}: mojibake (broken encoding)" if text.match?(MOJIBAKE)
    rescue ArgumentError => e
      @errors << "#{relative(file)}: #{e.message}"
    end

    def changed_vs_main
      diff = GenieEval.git('diff', '--name-only', 'main', '--', 'lib').split("\n")
      untracked = GenieEval.git('ls-files', '--others', '--exclude-standard', '--', 'lib').split("\n")
      (diff + untracked).uniq.sort
    end

    def relative(file)
      file.delete_prefix("#{REPO}/")
    end
  end
end

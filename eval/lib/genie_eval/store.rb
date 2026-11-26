# frozen_string_literal: true

module GenieEval
  # Reads and writes the committed eval data: cells, sets and labels.
  #
  #   eval/sets/<set>.jsonl    one row per case: its cells, pool, status, input, gold and why
  #   eval/labels/<set>.jsonl  the blind labeling passes of the set's drafted rows
  module Store
    # A row with no status has no labeling at all. `decided` and `excluded` are set by a person.
    STATUSES = %w[draft confirmed queued dropped decided excluded].freeze
    # Written and re-computed by eval:label from the passes; it never touches the others.
    LABELED = %w[draft queued confirmed dropped].freeze
    # A row runs with no status, or once labeling confirmed it or a person decided it. Any other
    # status, a typo included, keeps it out (eval:check reports the typo).
    RUNNING = %w[confirmed decided].freeze

    module_function

    def read_jsonl(file)
      return [] unless File.exist?(file)

      File.readlines(file, chomp: true).each_with_index.filter_map do |line, index|
        next if line.strip.empty?

        JSON.parse(line)
      rescue JSON::ParserError => e
        raise Error, "#{file}:#{index + 1}: #{e.message}"
      end
    end

    # Through a .tmp file, so an interrupted write never truncates a committed set.
    def write_jsonl(file, rows)
      FileUtils.mkdir_p(File.dirname(file))
      tmp = "#{file}.tmp"
      File.write(tmp, rows.map { |row| "#{JSON.generate(row)}\n" }.join)
      File.rename(tmp, file)
    end

    def write_json(file, data)
      FileUtils.mkdir_p(File.dirname(file))
      tmp = "#{file}.tmp"
      File.write(tmp, JSON.pretty_generate(data))
      File.rename(tmp, file)
    end

    # Read once per root; graders look cells up for every graded row.
    def cells
      @cells ||= JSON.parse(File.read(GenieEval.path('cells.json')))
    end

    def reset!
      @cells = nil
    end

    def cell(id)
      cells.find { |c| c['id'] == id } || raise(Error, "unknown cell #{id}")
    end

    def sets
      Dir.glob(GenieEval.path('sets', '*.jsonl')).map { |f| File.basename(f, '.jsonl') }.sort
    end

    def rows(set)
      read_jsonl(GenieEval.path('sets', "#{set}.jsonl"))
    end

    def write_rows(set, rows)
      write_jsonl(GenieEval.path('sets', "#{set}.jsonl"), rows)
    end

    def labels(set)
      read_jsonl(GenieEval.path('labels', "#{set}.jsonl"))
    end

    # The rows that run in a cell, from every set.
    def cases(cell_id)
      sets.flat_map { |set| rows(set) }.select { |row| Array(row['cells']).include?(cell_id) && runs?(row) }
    end

    def runs?(row)
      row['status'].nil? || RUNNING.include?(row['status'])
    end
  end
end

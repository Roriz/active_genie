# frozen_string_literal: true

module GenieEval
  # Reads and writes the committed eval data: cells, cases, gold and pools.
  module Store
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

    def write_jsonl(file, rows)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, rows.map { |row| "#{JSON.generate(row)}\n" }.join)
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

    def cases(cell_id)
      read_jsonl(GenieEval.path('cases', "#{cell_id}.jsonl"))
    end

    def gold(cell_id)
      read_jsonl(GenieEval.path('gold', "#{cell_id}.jsonl")).to_h { |row| [row['id'], row] }
    end

    def pools_file
      GenieEval.path('pools.jsonl')
    end

    def pools
      read_jsonl(pools_file)
    end

    def write_pools(rows)
      write_jsonl(pools_file, rows.sort_by { |r| [r['cell'], r['id']] })
    end
  end
end

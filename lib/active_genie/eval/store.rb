# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Reads and writes an eval's committed data:
    #
    #   evals/<name>/sets/<set>.jsonl    one row per case: pool, status, tags, input, gold and why
    #   evals/<name>/labels/<set>.jsonl  the blind labeling passes of the set's drafted rows
    module Store
      # A row with no status has no labeling step. `decided` and `excluded` are set by a person.
      STATUSES = %w[draft confirmed queued dropped decided excluded].freeze
      # Written and re-computed by `rake active_genie:eval:label` from the passes.
      LABELED = %w[draft queued confirmed dropped].freeze
      # A row runs with no status, or once labeling confirmed it or a person decided it.
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

      def sets(definition)
        Dir.glob(definition.path('sets', '*.jsonl')).map { |f| File.basename(f, '.jsonl') }.sort
      end

      def rows(definition, set)
        read_jsonl(definition.path('sets', "#{set}.jsonl"))
      end

      def write_rows(definition, set, rows)
        write_jsonl(definition.path('sets', "#{set}.jsonl"), rows)
      end

      def labels(definition, set)
        read_jsonl(definition.path('labels', "#{set}.jsonl"))
      end

      # [set, row] for every row of the eval that runs.
      def cases(definition)
        sets(definition).flat_map do |set|
          rows(definition, set).select { |row| runs?(row) }.map { |row| [set, row] }
        end
      end

      def runs?(row)
        row['status'].nil? || RUNNING.include?(row['status'])
      end
    end
  end
end

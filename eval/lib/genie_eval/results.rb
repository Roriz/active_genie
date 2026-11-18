# frozen_string_literal: true

module GenieEval
  # Grades the cached records of one run (or baseline) directory against the gold.
  class Results
    Row = Struct.new(:item, :record, :grade, keyword_init: true) do
      def pass? = grade.pass
      def key = item.key
    end

    attr_reader :rows

    # `root` holds r1/, r2/, ... ; `replicate` picks one of them.
    def self.load(root, items, replicate: 1)
      gold = Hash.new { |h, cell| h[cell] = Store.gold(cell) }
      rows = items.map do |item|
        file = File.join(root, "r#{replicate}", item.cell, "#{item.case['id']}.json")
        record = File.exist?(file) ? JSON.parse(File.read(file)) : nil
        gold_row = gold[item.cell][item.case['id']] || raise(Error, "no gold for #{item.key}")
        Row.new(item:, record:, grade: Graders.grade(item.cell, gold_row['gold'], record))
      end
      new(rows)
    end

    def initialize(rows)
      @rows = rows
    end

    def by_key
      @by_key ||= rows.to_h { |r| [r.key, r] }
    end

    def by_cell
      rows.group_by { |r| r.item.cell }
    end

    def missing
      rows.select { |r| r.record.nil? }
    end

    def errors
      rows.select { |r| r.record&.fetch('error', nil) }
    end

    # Pass/fail as 1/0 per cell, for the weighted mean and its bootstrap.
    def strata
      by_cell.transform_values { |cell_rows| cell_rows.map { |r| r.pass? ? 1 : 0 } }
    end
  end
end

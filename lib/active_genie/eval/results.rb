# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Grades the cached records of one run (or baseline) replicate against the rows' gold.
    class Results
      Row = Struct.new(:item, :record, :grade, keyword_init: true) do
        def pass? = grade.pass
        def key = item.key
      end

      attr_reader :rows

      def self.load(definition, root, items, replicate: 1)
        rows = items.map do |item|
          record = item.cached_record(File.join(root, "r#{replicate}", item.file))
          gold = item.gold || raise(MissingGoldError.new(definition.name, item.id))
          Row.new(item:, record:, grade: Graders.grade(definition, gold, record))
        end
        new(rows)
      end

      def initialize(rows)
        @rows = rows
      end

      def by_key
        @by_key ||= rows.to_h { |r| [r.key, r] }
      end

      def missing
        rows.select { |r| r.record.nil? }
      end

      def errors
        rows.select { |r| r.record&.fetch('error', nil) }
      end
    end
  end
end

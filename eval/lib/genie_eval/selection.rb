# frozen_string_literal: true

module GenieEval
  # Picks which cases a mode runs.
  #
  # quick: every case in the dev pool.
  # full:  every case in the dev and test pools.
  module Selection
    Item = Struct.new(:cell, :case, keyword_init: true) do
      def key
        "#{cell}/#{self.case['id']}"
      end

      def pool
        self.case['pool']
      end

      def gold
        self.case['gold']
      end

      # Identifies the exact input, so an output cached for an older version of the case is never reused.
      def input_sha
        @input_sha ||= Digest::SHA256.hexdigest(JSON.generate(self.case['input']))[0, 16]
      end

      # The cached record at `path` if it was produced from this input, else nil.
      def cached_record(path)
        return unless File.exist?(path)

        record = JSON.parse(File.read(path))
        record if record['input_sha'] == input_sha
      end
    end

    module_function

    def call(mode, cells: nil)
      wanted = cells && Array(cells)
      items = all_items.select { |item| wanted.nil? || wanted.include?(item.cell) }

      case mode.to_s
      when 'quick' then items.select { |i| i.pool == 'dev' }
      when 'full' then items
      else raise Error, "unknown mode #{mode}"
      end
    end

    def all_items
      Store.cells.flat_map do |cell|
        Store.cases(cell['id']).map { |kase| Item.new(cell: cell['id'], case: kase) }
      end
    end
  end
end

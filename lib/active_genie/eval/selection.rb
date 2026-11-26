# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Picks which cases a mode runs: `quick` the dev pool, `full` every case.
    module Selection
      Item = Struct.new(:set, :case, keyword_init: true) do
        def id = self.case['id']
        def key = id
        def pool = self.case['pool']
        def gold = self.case['gold']

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

      def call(definition, mode)
        items = Store.cases(definition).map { |set, row| Item.new(set:, case: row) }
        case mode.to_s
        when 'quick' then items.select { |i| i.pool == 'dev' }
        when 'full' then items
        else raise Error, "unknown mode #{mode}"
        end
      end
    end
  end
end

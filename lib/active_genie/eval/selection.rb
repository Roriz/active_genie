# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Picks which cases a mode runs: `quick` the dev pool, `full` every case, once per variant.
    module Selection
      # One case run by one variant (nil when the eval has a single `call`).
      Item = Struct.new(:set, :case, :variant, keyword_init: true) do
        def id = self.case['id']
        def key = variant ? "#{variant}/#{id}" : id
        def pool = self.case['pool']
        def gold = self.case['gold']

        # A twin row runs its input twice: as written, and with `twin` merged over it.
        def twin = self.case['twin']
        def input = self.case['input']
        def twin_input = twin && input.merge(twin)

        # Where its output is cached inside a replicate directory.
        def file = "#{key}.json"

        # Identifies the exact input, so an output cached for an older version of the case is never reused.
        def input_sha
          @input_sha ||= Digest::SHA256.hexdigest(JSON.generate(twin ? [input, twin] : input))[0, 16]
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
        rows = Store.cases(definition)
        items = definition.variant_names.flat_map do |variant|
          rows.map { |set, row| Item.new(set:, case: row, variant:) }
        end
        case mode.to_s
        when 'quick' then items.select { |i| i.pool == 'dev' }
        when 'full' then items
        else raise Error, "unknown mode #{mode}"
        end
      end
    end
  end
end

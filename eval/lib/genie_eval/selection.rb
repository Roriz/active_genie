# frozen_string_literal: true

module GenieEval
  # Picks which cases a mode runs.
  #
  # quick: the dev pool. Once a baseline has assigned roles, each cell runs its first
  #        `hard_per_cell` hard cases and `canary_per_cell` canaries (stable hash order).
  #        ALL_DEV=1 runs the whole dev pool.
  # full:  every case in the dev and test pools.
  module Selection
    Item = Struct.new(:cell, :case, :pool, :role, keyword_init: true) do
      def key
        "#{cell}/#{self.case['id']}"
      end
    end

    module_function

    def call(mode, cells: nil, all_dev: false)
      wanted = cells && Array(cells)
      items = all_items.select { |item| wanted.nil? || wanted.include?(item.cell) }

      case mode.to_s
      when 'quick' then quick(items.select { |i| i.pool == 'dev' }, all_dev:)
      when 'full' then items
      else raise Error, "unknown mode #{mode}"
      end
    end

    def all_items
      pools = Store.pools.to_h { |p| [[p['cell'], p['id']], p] }
      Store.cells.flat_map do |cell|
        Store.cases(cell['id']).filter_map do |kase|
          pool = pools[[cell['id'], kase['id']]]
          next unless pool

          Item.new(cell: cell['id'], case: kase, pool: pool['pool'], role: pool['role'])
        end
      end
    end

    def quick(items, all_dev:)
      return items if all_dev || items.none?(&:role)

      limits = GenieEval.config.fetch('quick')
      items.group_by(&:cell).flat_map do |_cell, cell_items|
        ordered = cell_items.sort_by { |i| Digest::SHA256.hexdigest(i.key) }
        ordered.select { |i| i.role == 'hard' }.first(limits['hard_per_cell']) +
          ordered.select { |i| i.role == 'canary' }.first(limits['canary_per_cell'])
      end
    end
  end
end

# frozen_string_literal: true

require 'async'

module ActiveGenie
  module FiberByBatch
    module_function

    def call(items, config:, &block)
      items.each_slice(config.llm.max_fibers).to_a.each do |batch|
        Async do
          tasks = batch.map do |item|
            Async { block.call(item) }
          end

          tasks.each(&:wait)
        end.wait
      end
    end
  end
end

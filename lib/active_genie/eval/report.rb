# frozen_string_literal: true

module ActiveGenie
  module Eval
    # A report as a list of blocks (headings, lines, tables), rendered either as aligned terminal text
    # or as markdown that pastes into a pull request. Both come from the same blocks, so they never drift.
    class Report
      Block = Struct.new(:kind, :text, :headers, :rows, keyword_init: true)

      attr_reader :blocks

      def initialize
        @blocks = []
      end

      def heading(text)
        @blocks << Block.new(kind: :heading, text:)
        self
      end

      def line(text)
        @blocks << Block.new(kind: :line, text:)
        self
      end

      def blank
        @blocks << Block.new(kind: :blank)
        self
      end

      # Label: value lines, labels aligned (a list in markdown).
      def pairs(rows)
        @blocks << Block.new(kind: :pairs, rows: rows.map { |label, value| [label.to_s, value.to_s] })
        self
      end

      # The first column is a label; numbers right-align.
      def table(headers, rows)
        @blocks << Block.new(kind: :table, headers: headers.map(&:to_s), rows: rows.map { |r| r.map(&:to_s) })
        self
      end

      def concat(other)
        @blocks.concat(other.blocks)
        self
      end

      def empty? = @blocks.empty?

      def to_text
        @blocks.flat_map do |block|
          case block.kind
          when :heading then ['', block.text]
          when :line then [block.text]
          when :blank then ['']
          when :table then text_table(block)
          when :pairs then text_pairs(block)
          end
        end.join("\n").sub(/\A\n+/, '')
      end

      def to_markdown
        @blocks.flat_map do |block|
          case block.kind
          when :heading then ['', "### #{block.text}", '']
          when :line then ["#{block.text}  "]
          when :blank then ['']
          when :table then ['', *markdown_table(block), '']
          when :pairs then ['', *block.rows.map { |label, value| "- **#{label}**: #{value}" }, '']
          end
        end.join("\n").gsub(/\n{3,}/, "\n\n").strip.concat("\n")
      end

      private

      # A column of numbers right-aligns, its header included; anything else left-aligns.
      def text_table(block)
        all = [block.headers, *block.rows]
        widths = block.headers.each_index.map { |i| all.map { |r| r[i].to_s.size }.max }
        right = block.headers.each_index.map { |i| i.positive? && block.rows.all? { |r| numeric?(r[i].to_s) } }
        all.map do |row|
          cells = row.each_with_index.map { |cell, i| right[i] ? cell.rjust(widths[i]) : cell.ljust(widths[i]) }
          "  #{cells.join('  ')}".rstrip
        end
      end

      def text_pairs(block)
        width = block.rows.map { |label, _| label.size }.max.to_i
        block.rows.map { |label, value| "  #{label.ljust(width)}  #{value}" }
      end

      def markdown_table(block)
        align = block.headers.each_index.map { |i| i.zero? ? ':--' : '--:' }
        [block.headers, align, *block.rows].map { |row| "| #{row.map { |c| c.to_s.gsub('|', '\\|') }.join(' | ')} |" }
      end

      def numeric?(cell)
        cell.match?(/\A[-+]?[\d.,]+%?\z|\A[·-]\z/)
      end
    end
  end
end

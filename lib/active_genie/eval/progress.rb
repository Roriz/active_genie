# frozen_string_literal: true

module ActiveGenie
  module Eval
    # The progress of a run, as one line:
    #
    #   [██████████░░░░░░] 5/8  62%  0:31 elapsed · ~0:19 left · 1 error · ~$0.02 so far
    #
    # On a terminal it redraws in place; elsewhere (CI, a log file) it prints a line at every 10%.
    class Progress
      WIDTH = 20

      def initialize(total:, io:, model: nil, label: nil, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @total = total
        @io = io
        @model = model
        @label = label
        @clock = clock
        @started = clock.call
        @done = 0
        @errors = 0
        @tokens = { 'input' => 0, 'output' => 0 }
        @mutex = Mutex.new
        @printed_step = -1
        draw if tty?
      end

      def tick(record)
        @mutex.synchronize do
          @done += 1
          @errors += 1 if record['error']
          @tokens['input'] += record.dig('usage', 'input_tokens').to_i
          @tokens['output'] += record.dig('usage', 'output_tokens').to_i
          draw
        end
      end

      def finish
        @io.puts if tty?
      end

      # Seconds as m:ss.
      def self.clock(seconds)
        seconds = seconds.round
        format('%d:%02d', seconds / 60, seconds % 60)
      end

      def line
        ratio = @total.zero? ? 1.0 : @done.to_f / @total
        filled = (ratio * WIDTH).round
        elapsed = @clock.call - @started
        parts = ["#{Progress.clock(elapsed)} elapsed"]
        parts << "~#{Progress.clock((elapsed / @done) * (@total - @done))} left" if @done.positive? && @done < @total
        parts << "#{@errors} error#{'s' unless @errors == 1}" if @errors.positive?
        usd = Runner.usd(@model, @tokens['input'], @tokens['output'])
        parts << format('~$%.2f so far', usd) if usd && (@tokens['input'] + @tokens['output']).positive?
        label = @label ? "#{@label} " : ''
        bar = ('█' * filled) + ('░' * (WIDTH - filled))
        format('%s[%s] %d/%d %3d%%  %s', label, bar, @done, @total, (ratio * 100).round, parts.join(' · '))
      end

      private

      def draw
        if tty?
          @io.print("\r#{line}\e[K")
        else
          step = @total.zero? ? 10 : (10 * @done / @total)
          return if step == @printed_step

          @printed_step = step
          @io.puts(line)
        end
      end

      def tty?
        @io.respond_to?(:tty?) && @io.tty?
      end
    end
  end
end

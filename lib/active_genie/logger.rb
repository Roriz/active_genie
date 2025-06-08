# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  class Logger
    def initialize(config: nil)
      @config = config || ActiveGenie.configuration.log
    end

    def call(data)
      log = data.merge(@config.additional_context)
                .merge(
                  timestamp: Time.now,
                  process_id: Process.pid
                )

      persist!(log)
      output_call(log)
      call_observers(log)

      log
    end

    def call_observers(log)
      return if @config.observers && @config.observers.empty?

      @config.call_observers(log)
    end

    def output_call(log)
      if @config.output
        @config.output.call(log)
      else
        $stdout.puts log
      end
    end

    def persist!(log)
      file_path = log.key?(:fine_tune) && log[:fine_tune] ? @config.fine_tune_file_path : @config.file_path
      folder_path = File.dirname(file_path)

      FileUtils.mkdir_p(folder_path)
      File.write(file_path, "#{JSON.generate(log)}\n", mode: 'a')
    end
  end
end

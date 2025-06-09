# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  class Logger
    def initialize(log_config: nil)
      @log_config = log_config || ActiveGenie.configuration.log
    end

    def call(data)
      log = data.merge(@log_config.additional_context)
                .merge(
                  timestamp: Time.now,
                  process_id: Process.pid
                )

      persist!(log)
      output_call(log)
      call_observers(log)

      log
    end

    def merge(log_config = nil)
      new(log_config:)
    end

    private

    def call_observers(log)
      Array(@log_config.observers).each do |observer|
        next unless observer[:scope].all? { |key, value| log[key.to_sym] == value }

        observer[:observer]&.call(log)
      rescue StandardError => e
        call(code: :observer_error, **observer, error: e.message)
      end
    end

    def output_call(log)
      if @log_config.output
        @log_config.output&.call(log)
      else
        $stdout.puts log
      end
    rescue StandardError => e
      call(code: :output_error, error: e.message)
    end

    def persist!(log)
      file_path = log_to_file_path(log)
      folder_path = File.dirname(file_path)

      FileUtils.mkdir_p(folder_path)
      File.write(file_path, "#{JSON.generate(log)}\n", mode: 'a')
    end

    def log_to_file_path(log)
      if log.key?(:fine_tune) && log[:fine_tune]
        @log_config.fine_tune_file_path
      else
        @log_config.file_path
      end
    end
  end
end

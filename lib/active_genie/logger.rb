# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  class Logger
    SINK_ERROR_CODES = %i[output_error observer_error].freeze

    def call(data, config:)
      log = data.merge(config.log.additional_context || {})
                .merge(
                  timestamp: Time.now,
                  process_id: Process.pid
                )

      persist!(log, config:)
      output_call(log, config:)
      call_observers(log, config:)

      log
    end

    private

    def call_observers(log, config:)
      Array(config.log.observers).each do |observer|
        next unless observer[:scope].all? { |key, value| log[key.to_sym] == value }

        observer[:observer]&.call(log)
      rescue StandardError => e
        report_sink_error(:observer_error, e, log, config:)
      end
    end

    def output_call(log, config:)
      if config.log.output
        config.log.output&.call(log)
      else
        $stdout.puts log
      end
    rescue StandardError => e
      report_sink_error(:output_error, e, log, config:)
    end

    # A failing output or observer must never break the caller's LLM call. The
    # failure is logged as its own entry, but a failure while delivering that
    # entry is dropped, so a sink that always raises cannot recurse.
    def report_sink_error(code, error, failed_log, config:)
      return if SINK_ERROR_CODES.include?(failed_log[:code])

      call({ code:, error: error.message, failed_code: failed_log[:code] }, config:)
    end

    def persist!(log, config:)
      file_path = if log.key?(:fine_tune) && log[:fine_tune]
                    config.log.fine_tune_file_path
                  else
                    config.log.file_path
                  end
      folder_path = File.dirname(file_path)

      FileUtils.mkdir_p(folder_path)
      File.write(file_path, "#{JSON.generate(log)}\n", mode: 'a')
    end
  end
end

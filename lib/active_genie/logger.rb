# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  class Logger
    def call(data, config: nil)
      log = data.merge(config&.additional_context || {})
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

    def call_observers(log, config: nil)
      Array(config&.observers).each do |observer|
        next unless observer[:scope].all? { |key, value| log[key.to_sym] == value }

        observer[:observer]&.call(log)
      rescue StandardError => e
        call(code: :observer_error, **observer, error: e.message)
      end
    end

    def output_call(log, config: nil)
      if config&.output
        config&.output&.call(log)
      else
        $stdout.puts log
      end
    rescue StandardError => e
      call(code: :output_error, error: e.message)
    end

    def persist!(log, config: nil)
      file_path = if log.key?(:fine_tune) && log[:fine_tune]
        config&.fine_tune_file_path
      else
        config&.file_path
      end
      folder_path = File.dirname(file_path)

      FileUtils.mkdir_p(folder_path)
      File.write(file_path, "#{JSON.generate(log)}\n", mode: 'a')
    end
  end
end

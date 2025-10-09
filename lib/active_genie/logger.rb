# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  class Logger
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
        call(code: :observer_error, **observer, error: e.message)
      end
    end

    def output_call(log, config:)
      if config.log.output
        config.log.output&.call(log)
      else
        $stdout.puts log
      end
    rescue StandardError => e
      call(code: :output_error, error: e.message)
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

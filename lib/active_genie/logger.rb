require 'json'
require 'fileutils'

module ActiveGenie
  module Logger
    module_function

    def info(log)
      save(log, level: :info)
    end

    def error(log)
      save(log, level: :error)
    end

    def warn(log)
      save(log, level: :warn)
    end

    def debug(log)
      save(log, level: :debug)
    end

    def trace(log)
      save(log, level: :trace)
    end

    LOG_LEVELS = { info: 0, error: 1, warn: 2, debug: 3, trace: 4 }.freeze

    def save(log, level: :info)
      return if LOG_LEVELS[log.dig(:log, :log_level)] || -1 < LOG_LEVELS[level]

      log[:trace] = log.dig(:trace)&.to_s&.gsub('ActiveGenie::', '')
      log[:timestamp] = Time.now
      log[:level] = level.to_s.upcase
      log[:process_id] = Process.pid

      FileUtils.mkdir_p('logs')
      File.write('logs/active_genie.log', "#{JSON.generate(log)}\n", mode: 'a')
      puts log

      log
    end
  end
end

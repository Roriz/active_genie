require 'json'
require 'fileutils'

module ActiveGenie
  module Logger
    module_function

    def info(data)
      save(data, level: :info)
    end

    def error(data)
      save(data, level: :error)
    end

    def warn(data)
      save(data, level: :warn)
    end

    def save(data, level: :info)
      trace = data.dig(:trace)&.to_s&.gsub('ActiveGenie::', '')
      log = {
        **data,
        trace:,
        timestamp: Time.now,
        level: level.to_s.upcase,
        process_id: Process.pid
      }

      FileUtils.mkdir_p('logs')
      File.write('logs/active_genie.log', "#{JSON.generate(log)}\n", mode: 'a')
      puts log

      log
    end
  end
end

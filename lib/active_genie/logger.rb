require 'json'
require 'fileutils'

module ActiveGenie
  module Logger
    module_function

    def with_context(context, observer: nil)
      @context ||= {}
      @observers ||= []
      begin
        @context = @context.merge(context)
        @observers << observer if observer
        yield if block_given?
      ensure
        @context.delete_if { |key, _| context.key?(key) }
        @observers.delete(observer)
      end
    end

    def info(log)
      call(log, level: :info)
    end

    def error(log)
      call(log, level: :error)
    end

    def warn(log)
      call(log, level: :warn)
    end

    def debug(log)
      call(log, level: :debug)
    end

    def trace(log)
      call(log, level: :trace)
    end

    def call(data, level: :info)
      log = {
        **@context,
        **(data || {}),
        timestamp: Time.now,
        level: level.to_s.upcase,
        process_id: Process.pid
      }

      append_to_file(log)
      output(log, level)
      call_observers(log)

      log
    end

    # Log Levels
    # 
    # LOG_LEVELS defines different levels of logging within the application. 
    # Each level serves a specific purpose, balancing verbosity and relevance.
    # 
    # - :info  -> General log messages providing an overview of application behavior, ensuring readability without excessive detail.
    # - :warn  -> Indicates unexpected behaviors that do not halt execution but require attention, such as retries, timeouts, or necessary conversions.
    # - :error -> Represents critical errors that prevent the application from functioning correctly.
    # - :debug -> Provides detailed logs for debugging, offering the necessary context for audits but with slightly less detail than trace logs.
    # - :trace -> Logs every external call with the highest level of detail, primarily for auditing or state-saving purposes. These logs do not provide context regarding triggers or reasons.
    LOG_LEVELS = { info: 0, error: 0, warn: 1, debug: 2, trace: 3 }.freeze

    attr_accessor :context
    
    def append_to_file(log)
      FileUtils.mkdir_p('logs')
      File.write('logs/active_genie.log', "#{JSON.generate(log)}\n", mode: 'a')
    end

    def output(log, level)
      config_log_level = LOG_LEVELS[log.dig(:config, :log_level)] || LOG_LEVELS[:info]
      if config_log_level >= LOG_LEVELS[level]
        $stdout.puts log
      else
        $stdout.print '.'
      end
    end

    def call_observers(log)
      @observers.each { |observer| observer.call(log) }
    end
  end
end

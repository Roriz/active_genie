require 'json'
require 'fileutils'

module ActiveGenie
  module Logger
    module_function

    def with_context(context)
      @context ||= {}
      begin
        @context = @context.merge(context)
        yield if block_given?
      ensure
        @context.delete_if { |key, _| context.key?(key) }
      end
    end

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

    def save(data, level: :info)
      log = @context.merge(data || {})
      log[:timestamp] = Time.now
      log[:level] = level.to_s.upcase
      log[:process_id] = Process.pid
      config_log_level = LOG_LEVELS[log.dig(:config, :log_level)] || LOG_LEVELS[:info]

      FileUtils.mkdir_p('logs')
      File.write('logs/active_genie.log', "#{JSON.generate(log)}\n", mode: 'a')
      if config_log_level >= LOG_LEVELS[level]
        $stdout.puts log
      else
        $stdout.print '.'
      end

      log
    end

    private

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
  end
end

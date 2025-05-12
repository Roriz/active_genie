# frozen_string_literal: true

require 'json'
require 'fileutils'

module ActiveGenie
  module Logger
    module_function

    def call(data)
      log = {
        **(@context || {}),
        **(data || {}),
        timestamp: Time.now,
        process_id: Process.pid
      }

      persist!(log)
      $stdout.puts log
      ActiveGenie.configuration.log.call_observers(log)

      log
    end

    def with_context(context)
      @context ||= {}
      begin
        @context = @context.merge(context)
        yield if block_given?
      ensure
        @context.delete_if { |key, _| context.key?(key) }
      end
    end

    attr_accessor :context

    def persist!(log)
      FileUtils.mkdir_p('log')
      File.write('log/active_genie.log', "#{JSON.generate(log)}\n", mode: 'a')
    end
  end
end

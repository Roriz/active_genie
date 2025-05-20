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
      config.output_call(log)

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
      file_path = log.key?(:fine_tune) && log[:fine_tune] ? config.fine_tune_file_path : config.file_path
      folder_path = File.dirname(file_path)

      FileUtils.mkdir_p(folder_path)
      File.write(file_path, "#{JSON.generate(log)}\n", mode: 'a')
    end

    def config
      ActiveGenie.configuration.log
    end
  end
end

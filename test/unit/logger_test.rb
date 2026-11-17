# frozen_string_literal: true

require 'tmpdir'
require_relative 'test_helper'

module ActiveGenie
  class LoggerTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir
      @received = []
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_a_raising_observer_is_logged_as_observer_error_and_the_call_continues
      config = build_config(observers: [failing_observer, recording_observer])

      log = Logger.new.call({ code: :hello }, config:)

      assert_equal :hello, log[:code]
      assert_equal %i[hello observer_error], @received.map { |entry| entry[:code] }.sort
      error = @received.find { |entry| entry[:code] == :observer_error }

      assert_equal 'observer broke', error[:error]
      assert_equal :hello, error[:failed_code]
    end

    def test_a_raising_output_is_logged_as_output_error_and_the_call_continues
      config = build_config(output: ->(_log) { raise 'output broke' }, observers: [recording_observer])

      Logger.new.call({ code: :hello }, config:)

      assert_equal %i[hello output_error], @received.map { |entry| entry[:code] }.sort
      assert_equal 'output broke', @received.find { |entry| entry[:code] == :output_error }[:error]
      assert_equal %w[hello output_error], persisted_codes
    end

    def test_a_sink_that_always_raises_is_reported_once_instead_of_recursing
      config = build_config(output: ->(_log) { raise 'output broke' }, observers: [failing_observer])

      Logger.new.call({ code: :hello }, config:)

      assert_equal %w[hello output_error observer_error], persisted_codes
    end

    private

    def build_config(output: ->(_log) {}, observers: [])
      Configuration.new(
        log: {
          file_path: File.join(@dir, 'active_genie.log'),
          fine_tune_file_path: File.join(@dir, 'fine_tune.log'),
          output:,
          observers: observers.map { |observer| { observer: } }
        }
      )
    end

    def failing_observer
      ->(_log) { raise 'observer broke' }
    end

    def recording_observer
      ->(log) { @received << log }
    end

    def persisted_codes
      File.readlines(File.join(@dir, 'active_genie.log')).map { |line| JSON.parse(line)['code'] }
    end
  end
end

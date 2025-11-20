# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class ExtractorConfig < BaseConfig
      attr_writer :min_accuracy

      def min_accuracy
        @min_accuracy ||= 70
      end
    end
  end
end

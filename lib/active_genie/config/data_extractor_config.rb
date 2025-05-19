# frozen_string_literal: true

module ActiveGenie
  module Config
    class DataExtractorConfig
      attr_accessor :with_explanation, :min_accuracy, :verbose

      def initialize
        @with_explanation = true
        @min_accuracy = 70
        @verbose = false
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.with_explanation = config_params[:with_explanation] if config_params[:with_explanation]
          config.min_accuracy = config_params[:min_accuracy] if config_params[:min_accuracy]
          config.verbose = config_params[:verbose] if config_params[:verbose]
        end
      end
    end
  end
end

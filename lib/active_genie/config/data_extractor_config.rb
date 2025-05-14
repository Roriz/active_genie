# frozen_string_literal: true

module ActiveGenie
  module Config
    class DataExtractorConfig
      attr_accessor :with_explanation

      def initialize
        @with_explanation = true
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.with_explanation = config_params[:with_explanation] if config_params[:with_explanation]
        end
      end
    end
  end
end

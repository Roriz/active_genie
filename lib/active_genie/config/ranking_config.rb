# frozen_string_literal: true

module ActiveGenie
  module Config
    class RankingConfig
      attr_accessor :score_variation_threshold

      def initialize
        @score_variation_threshold = 30
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.score_variation_threshold = config_params[:score_variation_threshold] if config_params[:score_variation_threshold]
        end
      end
    end
  end
end

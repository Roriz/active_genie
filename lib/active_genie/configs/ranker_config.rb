# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class RankerConfig < BaseConfig
      attr_writer :score_variation_threshold

      def score_variation_threshold
        @score_variation_threshold ||= 30
      end
    end
  end
end

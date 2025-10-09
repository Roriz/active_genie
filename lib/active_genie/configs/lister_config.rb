# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class ListerConfig < BaseConfig
      attr_writer :number_of_items

      def number_of_items
        @number_of_items ||= 5
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Config
    class FactoryConfig
      attr_accessor :number_of_items

      def initialize
        @number_of_items = 5
      end

      def merge(config_params = {})
        dup.tap do |config|
          config.number_of_items = config_params[:number_of_items] if config_params.key?(:number_of_items)
        end
      end
    end
  end
end

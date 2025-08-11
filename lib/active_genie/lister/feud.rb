# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie
  module Factory
    # The Factory::Feud class provides a foundation for generating a list of items for a given theme
    #
    # @example Feud usage with two players and criteria
    #   Feud.call("Industries that are most likely to be affected by climate change")
    #
    class Feud
      def self.call(...)
        new(...).call
      end

      # @param theme [String] The theme for the feud
      # @param config [Hash] Additional configuration options that modify the battle evaluation behavior
      # @return [Array of strings] List of items
      def initialize(theme, config: {})
        @theme = theme
        @config = ActiveGenie.configuration.merge(config)
      end

      # @return [Array] The list of items
      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'system', content: "List #{number_of_items} top items." },
          {  role: 'user', content: "theme: #{@theme}" }
        ]

        response = ::ActiveGenie::Clients::UnifiedClient.function_calling(
          messages,
          FUNCTION,
          config: @config
        )

        log_feud(response)
        response['items'] || []
      end

      PROMPT = File.read(File.join(__dir__, 'feud.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'feud.json')), symbolize_names: true)

      private

      def number_of_items
        @config.factory.number_of_items
      end

      def log_feud(response)
        @config.logger.call(
          code: :feud,
          theme: @theme[0..30],
          items: response['items'].map { |item| item[0..30] }
        )
      end
    end
  end
end

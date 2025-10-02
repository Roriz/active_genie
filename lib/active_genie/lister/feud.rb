# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Lister
    # The Lister::Feud class provides a foundation for generating a list of items for a given theme
    #
    # @example Feud usage with two players and criteria
    #   Feud.call("Industries that are most likely to be affected by climate change")
    #
    class Feud < ActiveGenie::BaseModule
      # @param theme [String] The theme for the feud
      # @param config [Hash] Additional configuration options
      # @return [Array of strings] List of items
      def initialize(theme, config: {})
        @theme = theme
        @initial_config = config
      end

      # @return [Array of strings] The list of items
      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'system', content: "List #{number_of_items} top items." },
          {  role: 'user', content: "theme: #{@theme}" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          FUNCTION,
          config:
        )

        ActiveGenie::Response.new(
          data: provider_response['items'] || [],
          reasoning: provider_response['items_explanation'],
          raw: provider_response
        )
      end

      PROMPT = File.read(File.join(__dir__, 'feud.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'feud.json')), symbolize_names: true)

      private

      def number_of_items
        config.lister.number_of_items
      end

      def config
        @config ||= begin
          c = ActiveGenie.configuration.merge(@initial_config)
          c.llm.recommended_model = 'deepseek-chat' unless c.llm.recommended_model

          c
        end
      end
    end
  end
end

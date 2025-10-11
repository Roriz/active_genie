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
        super(config:)
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
          reasoning: provider_response['why_these_items'],
          raw: provider_response
        )
      end

      PROMPT = File.read(File.join(__dir__, 'feud.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'feud.json')), symbolize_names: true)

      private

      def number_of_items
        config.lister.number_of_items
      end

      def module_config
        { llm: { recommended_model: 'deepseek-chat' } }
      end
    end
  end
end

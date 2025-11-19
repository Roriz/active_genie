# frozen_string_literal: true

require_relative '../providers/unified_provider'
require_relative 'debate'

module ActiveGenie
  module Comparator
    # The Fight class are comparation specialized in a fight between two fighters, like martial arts, heroes, characters.
    # The fight evaluation process simulate a fight using words, techniques, strategies, and reasoning.
    #
    # @example Fight usage with two fighters and criteria
    #   Fight.call("Naruto", "Sasuke", "How can win without using jutsu?")
    #
    class Fight < Debate
      # @return [ComparatorResponse] The evaluation result containing the winner and reasoning
      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "player_a: #{@player_a}" },
          {  role: 'user', content: "player_b: #{@player_b}" },
          {  role: 'user', content: "criteria: #{@criteria}" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          FUNCTION,
          config:
        )

        response_formatted(provider_response)
      end

      PROMPT = File.read(File.join(__dir__, 'fight.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'fight.json')), symbolize_names: true)
    end
  end
end

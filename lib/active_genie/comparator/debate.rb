# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Comparator
    # The Debate class provides a foundation for evaluating comparators between two players
    # using AI-powered evaluation. It determines a winner based on specified criteria,
    # analyzing how well each player meets the requirements. The winner is the impartial judge's
    # written pick; the per-player scores the model writes along the way are kept in the metadata.
    #
    # @example Debate usage with two players and criteria
    #   Debate.call("Player A content", "Player B content", "Evaluate keyword usage and pattern matching")
    #
    class Debate < ActiveGenie::BaseModule
      # @param player_a [String] The content or submission from the first player
      # @param player_b [String] The content or submission from the second player
      # @param criteria [String] The evaluation criteria or rules to assess against
      # @param config [Hash] Additional configuration options that modify the comparator evaluation behavior
      # @return [ActiveGenie::Result] The evaluation result containing winner and reasoning
      def initialize(player_a, player_b, criteria, config: {})
        @player_a = player_a
        @player_b = player_b
        @criteria = criteria
        super(config:)
      end

      # @return [ActiveGenie::Result] The evaluation result containing the winner and reasoning
      def call
        messages = [
          { role: 'system', content: PROMPT },
          { role: 'user', content: "player_a: #{@player_a}" },
          { role: 'user', content: "player_b: #{@player_b}" },
          { role: 'user', content: "criteria: #{@criteria}" }
        ]

        response_formatted(ActiveGenie::Providers::UnifiedProvider.function_calling(messages, FUNCTION, config:))
      end

      PROMPT = File.read(File.join(__dir__, 'debate.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'debate.json')), symbolize_names: true)

      private

      def response_formatted(data)
        winner = case data&.dig('impartial_judge_winner')
                 when 'player_a' then @player_a
                 when 'player_b' then @player_b
                 end

        ActiveGenie::Result.new(data: winner, reasoning: data&.dig('impartial_judge_winner_reasoning'),
                                metadata: data || {})
      end

      def module_config
        { llm: { recommended_model: 'claude-haiku-5-5' } }
      end
    end
  end
end

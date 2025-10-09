# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Comparator
    # The Debate class provides a foundation for evaluating comparators between two players
    # using AI-powered evaluation. It determines a winner based on specified criteria,
    # analyzing how well each player meets the requirements.
    #
    # The comparator evaluation process compares two players' content against given criteria
    # and returns detailed feedback including the winner and reasoning for the decision.
    #
    # @example Debate usage with two players and criteria
    #   Debate.call("Player A content", "Player B content", "Evaluate keyword usage and pattern matching")
    #
    class Debate < ActiveGenie::BaseModule
      # @param player_a [String] The content or submission from the first player
      # @param player_b [String] The content or submission from the second player
      # @param criteria [String] The evaluation criteria or rules to assess against
      # @param config [Hash] Additional configuration options that modify the comparator evaluation behavior
      # @return [ComparatorResponse] The evaluation result containing the winner and reasoning
      #   @return [String] :winner The winner, either player_a or player_b
      #   @return [String] :reasoning Detailed explanation of why the winner was chosen
      #   @return [String] :what_could_be_changed_to_avoid_draw A suggestion on how to avoid a draw
      def initialize(player_a, player_b, criteria, config: {})
        @player_a = player_a
        @player_b = player_b
        @criteria = criteria
        @initial_config = config
        super
      end

      # @return [ComparatorResponse] The evaluation result containing the winner and reasoning
      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "player_a: #{@player_a}" },
          {  role: 'user', content: "player_b: #{@player_b}" },
          {  role: 'user', content: "criteria: #{@criteria}" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(messages, FUNCTION, config:)

        response_formatted(provider_response)
      end

      PROMPT = File.read(File.join(__dir__, 'debate.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'debate.json')), symbolize_names: true)

      private

      def response_formatted(provider_response)
        winner, = case provider_response['impartial_judge_winner']
                  when 'player_a' then [@player_a, @player_b]
                  when 'player_b' then [@player_b, @player_a]
                  end
        reasoning = provider_response['impartial_judge_winner_reasoning']

        ActiveGenie::Response.new(data: winner, reasoning:, raw: provider_response)
      end

      def config
        @config ||= ActiveGenie.new_configuration(
          ActiveGenie::DeepMerge.call(
            { llm: { recommended_model: 'deepseek-chat' } },
            @initial_config
          )
        )
      end
    end
  end
end

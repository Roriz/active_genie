# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie
  module Battle
    # The Generalist class provides a foundation for evaluating battles between two players
    # using AI-powered evaluation. It determines a winner based on specified criteria,
    # analyzing how well each player meets the requirements.
    #
    # The battle evaluation process compares two players' content against given criteria
    # and returns detailed feedback including the winner and reasoning for the decision.
    #
    # @example Generalist usage with two players and criteria
    #   Generalist.call("Player A content", "Player B content", "Evaluate keyword usage and pattern matching")
    #
    class Generalist
      def self.call(...)
        new(...).call
      end

      # @param player_a [String] The content or submission from the first player
      # @param player_b [String] The content or submission from the second player
      # @param criteria [String] The evaluation criteria or rules to assess against
      # @param config [Hash] Additional configuration options that modify the battle evaluation behavior
      # @return [Hash] The evaluation result containing the winner and reasoning
      #   @return [String] :winner The winner, either player_a or player_b
      #   @return [String] :reasoning Detailed explanation of why the winner was chosen
      #   @return [String] :what_could_be_changed_to_avoid_draw A suggestion on how to avoid a draw
      def initialize(player_a, player_b, criteria, config: {})
        @player_a = player_a
        @player_b = player_b
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
      end

      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "criteria: #{@criteria}" },
          {  role: 'user', content: "player_a: #{@player_a}" },
          {  role: 'user', content: "player_b: #{@player_b}" }
        ]

        response = ::ActiveGenie::Clients::UnifiedClient.function_calling(
          messages,
          FUNCTION,
          config: @config
        )

        ActiveGenie::Logger.call({
                                   code: :battle,
                                   player_a: @player_a[0..30],
                                   player_b: @player_b[0..30],
                                   criteria: @criteria[0..30],
                                   winner: response['impartial_judge_winner'],
                                   reasoning: response['impartial_judge_winner_reasoning']
                                 })

        response_formatted(response)
      end

      private

      def response_formatted(response)
        winner = response['impartial_judge_winner']
        loser = case response['impartial_judge_winner']
                when 'player_a' then 'player_b'
                when 'player_b' then 'player_a'
                end

        { 'winner' => winner, 'loser' => loser, 'reasoning' => response['impartial_judge_winner_reasoning'] }
      end

      PROMPT = <<~PROMPT
        Based on two players, player_a and player_b, they will battle against each other based on criteria. Criteria are vital as they provide a clear metric to compare the players. Follow these criteria strictly.

        # Steps
        1. player_a presents their strengths and how they meet the criteria. Max of 100 words.
        2. player_b presents their strengths and how they meet the criteria. Max of 100 words.
        3. player_a argues why they should be the winner compared to player_b. Max of 100 words.
        4. player_b counter-argues why they should be the winner compared to player_a. Max of 100 words.
        5. The impartial judge chooses the winner.

        # Output Format
        - The impartial judge chooses this player as the winner.

        # Notes
        - Avoid resulting in a draw. Use reasoning or make fair assumptions if needed.
        - Critically assess each player's adherence to the criteria.
        - Clearly communicate the reasoning behind your decision.
      PROMPT

      FUNCTION = {
        name: 'battle_evaluation',
        description: 'Evaluate a battle between player_a and player_b using predefined criteria and identify the winner.',
        parameters: {
          type: 'object',
          properties: {
            player_a_sell_himself: {
              type: 'string',
              description: 'player_a presents their strengths and how they meet the criteria. Max of 100 words.'
            },
            player_b_sell_himself: {
              type: 'string',
              description: 'player_b presents their strengths and how they meet the criteria. Max of 100 words.'
            },
            player_a_arguments: {
              type: 'string',
              description: 'player_a arguments for why they should be the winner compared to player_b. Max of 100 words.'
            },
            player_b_counter: {
              type: 'string',
              description: 'player_b counter arguments for why they should be the winner compared to player_a. Max of 100 words.'
            },
            impartial_judge_winner_reasoning: {
              type: 'string',
              description: 'The detailed reasoning about why the impartial judge chose the winner. Max of 100 words.'
            },
            impartial_judge_winner: {
              type: 'string',
              description: 'Who is the winner based on the impartial judge reasoning?',
              enum: %w[player_a player_b]
            }
          },
          required: %w[player_a_sell_himself player_b_sell_himself player_a_arguments player_b_counter
                       impartial_judge_winner_reasoning impartial_judge_winner]
        }
      }.freeze
    end
  end
end

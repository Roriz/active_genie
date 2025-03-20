# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie::Battle
  # The Basic class provides a foundation for evaluating battles between two players
  # using AI-powered evaluation. It determines a winner based on specified criteria,
  # analyzing how well each player meets the requirements.
  #
  # The battle evaluation process compares two players' content against given criteria
  # and returns detailed feedback including the winner and reasoning for the decision.
  #
  # @example Basic usage with two players and criteria
  #   Basic.call("Player A content", "Player B content", "Evaluate keyword usage and pattern matching")
  #
  class Basic
    def self.call(...)
      new(...).call
    end

    # @param player_a [String] The content or submission from the first player
    # @param player_b [String] The content or submission from the second player
    # @param criteria [String] The evaluation criteria or rules to assess against
    # @param config [Hash] Additional configuration config that modify the battle evaluation behavior
    # @return [Hash] The evaluation result containing the winner and reasoning
    #   @return [String] :winner The @param player_a or player_b
    #   @return [String] :reasoning Detailed explanation of why the winner was chosen
    #   @return [String] :what_could_be_changed_to_avoid_draw A suggestion on how to avoid a draw
    def initialize(player_a, player_b, criteria, config: {})
      @player_a = player_a
      @player_b = player_b
      @criteria = criteria
      @config = ActiveGenie::Configuration.to_h(config)
    end

    def call
      messages = [
        {  role: 'system', content: PROMPT },
        {  role: 'user', content: "criteria: #{@criteria}" },
        {  role: 'user', content: "player_a: #{@player_a}" },
        {  role: 'user', content: "player_b: #{@player_b}" },
      ]

      response = ::ActiveGenie::Clients::UnifiedClient.function_calling(
        messages,
        FUNCTION,
        model_tier: 'lower_tier',
        config: @config
      )

      ActiveGenie::Logger.debug({
        step: :battle,
        player_a: @player_a.content[0..30],
        player_b: @player_b.content[0..30],
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
              else 'draw'
              end

      { winner:, loser:, reasoning: response['impartial_judge_winner_reasoning'] }
    end

    PROMPT = <<~PROMPT
    Based on two players, player_a and player_b, they will battle against each other based on criteria. Criteria are vital as they provide a clear metric to compare the players. Follow these criteria strictly.

    # Steps
    1. Player_a sells himself, highlighting his strengths and how he meets the criteria. Max of 100 words.
    2. Player_b sells himself, highlighting his strengths and how he meets the criteria. Max of 100 words.
    3. Player_a argues why he is the winner compared to player_b. Max of 100 words.
    4. Player_b counter-argues why he is the winner compared to player_a. Max of 100 words.
    5. The impartial judge chooses which player as the winner.

    # Output Format
    - The impartial judge chooses this player as the winner.

    # Notes
    - Avoid resulting in a draw. Use reasoning or make fair assumptions if needed.
    - Critically assess each player's adherence to the criteria.
    - Clearly communicate the reasoning behind your decision.
    PROMPT

    FUNCTION =  {
      name: 'battle_evaluation',
      description: 'Evaluate a battle between player_a and player_b using predefined criteria and identify the winner.',
      schema: {
        type: "object",
        properties: {
          player_a_sell_himself: {
            type: 'string',
            description: 'player_a sell himself, highlighting his strengths and how he meets the criteria. Max of 100 words.',
          },
          player_b_sell_himself: {
            type: 'string',
            description: 'player_b sell himself, highlighting his strengths and how he meets the criteria. Max of 100 words.',
          },
          player_a_arguments: {
            type: 'string',
            description: 'player_a arguments why he is the winner compared to player_b. Max of 100 words.',
          },
          player_b_counter: {
            type: 'string',
            description: 'player_b counter arguments why he is the winner compared to player_a. Max of 100 words.',
          },
          impartial_judge_winner_reasoning: {
            type: 'string',
            description: 'The detailed reasoning about why the impartial judge chose the winner. Max of 100 words.',
          },
          impartial_judge_winner: {
            type: 'string',
            description: 'The impartial judge chose this player as the winner.',
            enum: ['player_a', 'player_b', 'draw']
          },
        }
      }
    }
  end
end

# frozen_string_literal: true

require_relative '../clients/router'

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
    def self.call(player_a, player_b, criteria, options: {})
      new(player_a, player_b, criteria, options:).call
    end

    # @param player_a [String] The content or submission from the first player
    # @param player_b [String] The content or submission from the second player
    # @param criteria [String] The evaluation criteria or rules to assess against
    # @param options [Hash] Additional configuration options that modify the battle evaluation behavior
    # @return [Hash] The evaluation result containing the winner and reasoning
    #   @return [String] :winner_player The @param player_a or player_b
    #   @return [String] :reasoning Detailed explanation of why the winner was chosen
    #   @return [String] :what_could_be_changed_to_avoid_draw A suggestion on how to avoid a draw
    def initialize(player_a, player_b, criteria, options: {})
      @player_a = player_a
      @player_b = player_b
      @criteria = criteria
      @options = options
    end

    def call
      messages = [
        {  role: 'system', content: PROMPT },
        {  role: 'user', content: "criteria: #{@criteria}" },
        {  role: 'user', content: "player_a: #{player_content(@player_a)}" },
        {  role: 'user', content: "player_b: #{player_content(@player_b)}" },
      ]

      response = ::ActiveGenie::Clients::Router.function_calling(messages, FUNCTION, options: @options)

      response['winner_player'] = @player_a if response['winner_player'] == 'player_a'
      response['winner_player'] = @player_b if response['winner_player'] == 'player_b'

      response
    end

    private

    def player_content(player)
      return player.dig('content') if player.is_a?(Hash)

      player
    end

    PROMPT = <<~PROMPT
    Evaluate a battle between player_a and player_b using predefined criteria and identify the winner.

    Consider rules, keywords, and patterns as the criteria for evaluation. Analyze the content from both players objectively, focusing on who meets the criteria most effectively. Explain your decision clearly, with specific reasoning on how the chosen player fulfilled the criteria better than the other. Avoid selecting a draw unless absolutely necessary.

    # Steps
    1. **Review Predefined Criteria**: Understand the specific rules, keywords, and patterns that serve as the basis for evaluation.
    2. **Analyze Content**: Examine the contributions of both player_a and player_b. Look for how each player meets or fails to meet the criteria.
    3. **Comparison**: Compare both players against each criterion to determine who aligns better with the standards set.
    4. **Decision-Making**: Based on the analysis, determine the player who meets the most or all criteria effectively.
    5. **Provide Justification**: Offer a clear and concise reason for your choice detailing how the winner outperformed the other.

    # Examples
    - **Example 1**:
      - Input: Player A uses keyword X, follows rule Y, Player B uses keyword Z, breaks rule Y.
      - Output: winner_player: player_a
        - Justification: Player A successfully used keyword X and followed rule Y, whereas Player B broke rule Y.

    - **Example 2**:
      - Input: Player A matches pattern P, Player B matches pattern P, uses keyword Q.
      - Output: winner_player: player_b
        - Justification: Both matched pattern P, but Player B also used keyword Q, meeting more criteria.

    # Notes
    - Avoid drawing if a clear winner can be discerned.
    - Critically assess each player's adherence to the criteria.
    - Clearly communicate the reasoning behind your decision.
    PROMPT

    FUNCTION =  {
      name: 'battle_evaluation',
      description: 'Evaluate a battle between player_a and player_b using predefined criteria and identify the winner.',
      schema: {
        type: "object",
        properties: {
          winner_player: {
            type: 'string',
            description: 'The player who won the battle based on the criteria.',
            enum: ['player_a', 'player_b', 'draw']
          },
          reasoning_of_winner: {
            type: 'string',
            description: 'The detailed reasoning about why the winner won based on the criteria.',
          },
          what_could_be_changed_to_avoid_draw: {
            type: 'string',
            description: 'Suggestions on how to avoid a draw based on the criteria. Be as objective and short as possible. Can be empty.',
          }
        }
      }
    }
  end
end

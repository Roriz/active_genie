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
      BattleResponse = Struct.new(:winner, :loser, :reasoning, :raw, keyword_init: true)

      def self.call(...)
        new(...).call
      end

      # @param player_a [String] The content or submission from the first player
      # @param player_b [String] The content or submission from the second player
      # @param criteria [String] The evaluation criteria or rules to assess against
      # @param config [Hash] Additional configuration options that modify the battle evaluation behavior
      # @return [BattleResponse] The evaluation result containing the winner and reasoning
      #   @return [String] :winner The winner, either player_a or player_b
      #   @return [String] :reasoning Detailed explanation of why the winner was chosen
      #   @return [String] :what_could_be_changed_to_avoid_draw A suggestion on how to avoid a draw
      def initialize(player_a, player_b, criteria, config: {})
        @player_a = player_a
        @player_b = player_b
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
      end

      # @return [BattleResponse] The evaluation result containing the winner and reasoning
      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "player_a: #{@player_a}" },
          {  role: 'user', content: "player_b: #{@player_b}" },
          {  role: 'user', content: "criteria: #{@criteria}" },
        ]

        response = ::ActiveGenie::Clients::UnifiedClient.function_calling(
          messages,
          FUNCTION,
          config: @config
        )

        response_formatted(response)
      end

      PROMPT = File.read(File.join(__dir__, 'generalist.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'generalist.json')), symbolize_names: true)

      private

      def response_formatted(response)
        winner, loser = case response['impartial_judge_winner']
                        when 'player_a' then [@player_a, @player_b]
                        when 'player_b' then [@player_b, @player_a]
                        end
        reasoning = response['impartial_judge_winner_reasoning']

        battle_response = BattleResponse.new(winner:, loser:, reasoning:, raw: response)
        log_battle(battle_response)

        battle_response
      end

      def log_battle(battle_response)
        @config.logger.call(
          code: :battle,
          player_a: @player_a[0..30],
          player_b: @player_b[0..30],
          criteria: @criteria[0..30],
          **battle_response.to_h
        )
      end
    end
  end
end

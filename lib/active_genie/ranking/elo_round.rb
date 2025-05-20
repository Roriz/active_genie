# frozen_string_literal: true

require_relative '../battle/generalist'

module ActiveGenie
  module Ranking
    class EloRound
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, config: {})
        @players = players
        @relegation_tier = players.calc_relegation_tier
        @defender_tier = players.calc_defender_tier
        @criteria = criteria
        @config = config
        @tmp_defenders = []
        @start_time = Time.now
        @total_tokens = 0
        @previous_elo = {}
        @previous_highest_elo = @defender_tier.max_by(&:elo).elo
      end

      def call
        ActiveGenie::Logger.with_context(log_context) do
          save_previous_elo
          matches.each do |player_a, player_b|
            # TODO: battle can take a while, can be parallelized
            winner, loser = battle(player_a, player_b)
            next if winner.nil? || loser.nil?

            winner.elo = calculate_new_elo(winner.elo, loser.elo, 1)
            loser.elo = calculate_new_elo(loser.elo, winner.elo, 0)
          end
        end

        ActiveGenie::Logger.call({ code: :elo_round_report, **report })

        report
      end

      private

      BATTLE_PER_PLAYER = 3
      K = 32

      def save_previous_elo
        @previous_elo = @players.map { |player| [player.id, player.elo] }.to_h
      end

      def matches
        @relegation_tier.each_with_object([]) do |attack_player, matches|
          BATTLE_PER_PLAYER.times do
            matches << [attack_player, next_defense_player].shuffle
          end
        end
      end

      def next_defense_player
        @tmp_defenders = @defender_tier.shuffle if @tmp_defenders.empty?

        @tmp_defenders.pop
      end

      def battle(player_a, player_b)
        ActiveGenie::Logger.with_context({ player_a_id: player_a.id, player_b_id: player_b.id }) do
          result = ActiveGenie::Battle.call(
            player_a.content,
            player_b.content,
            @criteria,
            config: @config
          )

          winner, loser = case result['winner']
                          when 'player_a' then [player_a, player_b]
                          when 'player_b' then [player_b, player_a]
                          when 'draw' then [nil, nil]
                          end

          [winner, loser]
        end
      end

      # INFO: Read more about the Elo rating system on https://en.wikipedia.org/wiki/Elo_rating_system
      def calculate_new_elo(player_rating, opponent_rating, score)
        expected_score = 1.0 / (1.0 + 10.0**((opponent_rating - player_rating) / 400.0))

        player_rating + (K * (score - expected_score)).round
      end

      def log_context
        { elo_round_id: }
      end

      def elo_round_id
        relegation_tier_ids = @relegation_tier.map(&:id).join(',')
        defender_tier_ids = @defender_tier.map(&:id).join(',')

        ranking_unique_key = [relegation_tier_ids, defender_tier_ids, @criteria, @config.to_json].join('-')
        Digest::MD5.hexdigest(ranking_unique_key)
      end

      def report
        {
          elo_round_id:,
          players_in_round: players_in_round.map(&:id),
          battles_count: matches.size,
          duration_seconds: Time.now - @start_time,
          total_tokens: @total_tokens,
          previous_highest_elo: @previous_highest_elo,
          highest_elo:,
          highest_elo_diff: highest_elo - @previous_highest_elo,
          players_elo_diff:
        }
      end

      def players_in_round
        @defender_tier + @relegation_tier
      end

      def highest_elo
        players_in_round.max_by(&:elo).elo
      end

      def players_elo_diff
        players_in_round.map do |player|
          [player.id, player.elo - @previous_elo[player.id]]
        end.sort_by { |_, diff| -diff }.to_h
      end

      def log_observer(log)
        @total_tokens += log[:total_tokens] if log[:code] == :llm_usage
      end
    end
  end
end

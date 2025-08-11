# frozen_string_literal: true

module ActiveGenie
  module Ranker
    class Elo
      def self.call(...)
        new(...).call
      end

      def initialize(players, criteria, config: nil)
        @players = players
        @higher_tier = players.calc_higher_tier
        @lower_tier = players.calc_lower_tier
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
        @tmp_highers = []
        @total_tokens = 0
        @previous_elo = @players.to_h { |player| [player.id, player.elo] }
        @previous_highest_elo = @higher_tier.max_by(&:elo).elo
      end

      def call
        @config.log.add_observer(observers: ->(log) { log_observer(log) })
        @config.log.additional_context = { elo_id: }

        matches.each do |player_a, player_b|
          # TODO: battle can take a while, can be parallelized
          winner, loser = battle(player_a, player_b)
          update_players_elo(winner, loser)
        end

        build_report
      end

      BATTLE_PER_PLAYER = 3
      K = 32

      private

      def matches
        match_keys = {}

        @higher_tier.each_with_object([]) do |attack_player, matches|
          BATTLE_PER_PLAYER.times do
            higher_player = next_higher_player

            next if match_keys["#{attack_player.id}_#{higher_player.id}"]

            match_keys["#{attack_player.id}_#{higher_player.id}"] = true
            matches << [attack_player, higher_player]
          end
        end
      end

      def next_higher_player
        @tmp_highers = @higher_tier.shuffle if @tmp_highers.empty?

        @tmp_highers.pop
      end

      def battle(player_a, player_b)
        result = ActiveGenie::Battle.call(
          player_a.content,
          player_b.content,
          @criteria,
          config: @config.merge(additional_context: { player_a_id: player_a.id, player_b_id: player_b.id })
        )

        winner, loser = case result['winner']
                        when 'player_a' then [player_a, player_b]
                        when 'player_b' then [player_b, player_a]
                        when 'draw' then [nil, nil]
                        end

        [winner, loser]
      end

      def update_players_elo(winner, loser)
        return if winner.nil? || loser.nil?

        winner.elo = calculate_new_elo(winner.elo, loser.elo, 1)
        loser.elo = calculate_new_elo(loser.elo, winner.elo, 0)
      end

      # INFO: Read more about the Elo rating system on https://en.wikipedia.org/wiki/Elo_rating_system
      def calculate_new_elo(player_rating, opponent_rating, score)
        expected_score = 1.0 / (1.0 + (10.0**((opponent_rating - player_rating) / 400.0)))

        player_rating + (K * (score - expected_score)).round
      end

      def elo_id
        @elo_id ||= begin
          higher_tier_ids = @higher_tier.map(&:id).join(',')
          lower_tier_ids = @lower_tier.map(&:id).join(',')

          ranking_unique_key = [higher_tier_ids, lower_tier_ids, @criteria, @config.to_json].join('-')
          Digest::MD5.hexdigest(ranking_unique_key)
        end
      end

      def build_report
        report = {
          elo_id:,
          players_in: players_in.map(&:id),
          battles_count: matches.size,
          total_tokens: @total_tokens,
          previous_highest_elo: @previous_highest_elo,
          highest_elo:,
          highest_elo_diff: highest_elo - @previous_highest_elo,
          players_elo_diff:
        }

        @config.logger.call({ elo_id:, code: :elo_report, **report })

        report
      end

      def players_in
        @lower_tier + @higher_tier
      end

      def highest_elo
        players_in.max_by(&:elo).elo
      end

      def players_elo_diff
        elo_diffs = players_in.map do |player|
          [player.id, player.elo - @previous_elo[player.id]]
        end
        elo_diffs.sort_by { |_, diff| -(diff || 0) }.to_h
      end

      def log_observer(log)
        @total_tokens += log[:total_tokens] if log[:code] == :llm_usage
      end
    end
  end
end

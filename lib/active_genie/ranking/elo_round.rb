require_relative '../battle/basic'

module ActiveGenie::Ranking
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
    end

    def call
      ActiveGenie::Logger.with_context(log_context) do
        matches.each do |player_1, player_2|
          # TODO: battle can take a while, can be parallelized
          winner, loser = battle(player_1, player_2)

          next if winner.nil? || loser.nil?

          new_winner_elo, new_loser_elo = calculate_new_elo(winner.elo, loser.elo)

          winner.elo = new_winner_elo
          loser.elo = new_loser_elo
        end
      end

      ActiveGenie::Logger.info({ step: :elo_round_report, **report })

      report
    end

    private

    BATTLE_PER_PLAYER = 3
    LOSE_PENALTY = 15
    K = 32

    def matches
      @relegation_tier.reduce([]) do |matches, attack_player|
        BATTLE_PER_PLAYER.times do
          matches << [attack_player, next_defense_player].shuffle
        end
        matches
      end
    end

    def next_defense_player
      @tmp_defenders = @defender_tier if @tmp_defenders.size.zero?

      @tmp_defenders.shuffle.pop
    end

    def battle(player_1, player_2)
      ActiveGenie::Logger.with_context({ player_1_id: player_1.id, player_2_id: player_2.id }) do
        result = ActiveGenie::Battle.basic(
          player_1,
          player_2,
          @criteria,
          config: @config
        )

        winner, loser = case result['winner']
          when 'player_1' then [player_1, player_2]
          when 'player_2' then [player_2, player_1]
          when 'draw' then [nil, nil]
        end

        [winner, loser]
      end
    end

    # INFO: Read more about the Elo rating system on https://en.wikipedia.org/wiki/Elo_rating_system
    def calculate_new_elo(winner_elo, loser_elo)
      expected_score_a = 1 / (1 + 10**((loser_elo - winner_elo) / 400))
      expected_score_b = 1 - expected_score_a

      new_winner_elo = [winner_elo + K * (1 - expected_score_a), max_defense_elo].min
      new_loser_elo = [loser_elo + K * (1 - expected_score_b) - LOSE_PENALTY, min_relegation_elo].max

      [new_winner_elo, new_loser_elo]
    end

    def max_defense_elo
      @defender_tier.max_by(&:elo).elo
    end

    def min_relegation_elo
      @relegation_tier.min_by(&:elo).elo
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
        battles_count: matches.size,
        duration_seconds: Time.now - @start_time,
        total_tokens: @total_tokens,
      }
    end

    def log_observer(log)
      @total_tokens += log[:total_tokens] if log[:step] == :llm_stats
    end
  end
end

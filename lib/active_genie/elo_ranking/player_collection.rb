module ActiveGenie::EloRanking
  class PlayerCollection
    def self.build(raw)
      new(raw).build
    end

    def initialize(raw)
      @raw = raw
      @players = []
    end

    def build
      @players = @raw.map do |player|
        player[:elo] = player[:score] * 10 + BASE_RATING unless player.key?(:elo)

        player
      end
      
      if high_elo_variance?
        @players = @players.map { |player| { **player, eliminated: player[:elo] >= quarter_percentile } }
      end

      @players = @players.sort_by { |player| player[:elo] }

      self
    end

    def eligible
      @players.reject { |player| player[:eliminated] }
    end

    def batch_size
      [[eligible.length / 3, 10].max, eligible.length - 9].min
    end

    def relegation_players
      eligible[(batch_size*-1)..-1]
    end

    def defense_players
      eligible[(batch_size*-2)...(batch_size*-1)]
    end

    private

    BASE_RATING = 950
    HIGH_ELO_VARIANCE_THRESHOLD = 0.3

    def all_elos
      @players.map { |player| player[:elo] }.sort
    end

    def quarter_percentile
      all_elos.first(all_elos.length/4)
    end
    
    def high_elo_variance?
      stdev = ActiveGenie::Utils.standard_deviation(all_elos)
      avg = all_elos.sum / all_elos.length

      avg / stdev >= HIGH_ELO_VARIANCE_THRESHOLD
    end
  end
end
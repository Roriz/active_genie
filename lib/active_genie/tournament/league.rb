module ActiveGenie::EloRanking
  class League
    def self.call(players, criteria, options: {})
      new(players, criteria, options:).call
    end

    def initialize(players, criteria, options: {})
      @players = players
      @criteria = criteria
      @options = options
    end

    def call
      # TODO:
      @players
    end
  end
end

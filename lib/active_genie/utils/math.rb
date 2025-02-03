module ActiveGenie::Utils
  module Math
    module_function

    def self.calculate_new_elo(winner, loser, k: 32)
      expected_score_a = 1 / (1 + 10**((loser - winner) / 400))
      expected_score_b = 1 - expected_score_a

      new_elo_winner = winner + k * (1 - expected_score_a)
      new_elo_loser = loser + k * (1 - expected_score_b)

      [new_elo_winner, new_elo_loser]
    end
  end
end
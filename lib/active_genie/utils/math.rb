module ActiveGenie::Utils
  module Math
    module_function

    def self.standard_deviation(values)
      avg = values.sum / values.length
      sum_squared_differences = values.inject(0){|accum, i| accum +(i-avg)**2 }
      sample_variance = sum_squared_differences/(values.length - 1).to_f

      ::Math.sqrt(sample_variance)
    end

    def self.calculate_new_elo(winner, loser, k: 32)
      expected_score_a = 1 / (1 + 10**((loser - winner) / 400))
      expected_score_b = 1 - expected_score_a

      new_elo_winner = winner + k * (1 - expected_score_a)
      new_elo_loser = loser + k * (1 - expected_score_b)

      [new_elo_winner, new_elo_loser]
    end

    def self.percentile(list_of_numbers, percent)
      index = percent * (list_of_numbers.length - 1)
      lower = list_of_numbers.min
      upper = list_of_numbers.max

      lower + (upper - lower) * (index % 1)
    end
  end
end
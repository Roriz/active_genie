module ActiveGenie::Utils
  def self.standard_deviation(values)
    avg = values.sum / values.length
    sum_squared_differences = values.inject(0){|accum, i| accum +(i-avg)**2 }
    sample_variance = sum_squared_differences/(values.length - 1).to_f

    Math.sqrt(sample_variance)
  end
end
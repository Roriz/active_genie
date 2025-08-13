# frozen_string_literal: true

require_relative 'scorer/jury_bench'

module ActiveGenie
  module Scorer
    module_function

    def call(...)
      JuryBench.call(...)
    end

    def by_jury_bench(...)
      JuryBench.call(...)
    end
  end
end

# frozen_string_literal: true

require_relative 'scorer/jury_bench'

module ActiveGenie
  module Scorer
    module_function
    
    def_delegator :JuryBench, :call
    def_delegator :JuryBench, :call, :by_jury_bench
  end
end

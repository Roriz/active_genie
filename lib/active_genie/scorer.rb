# frozen_string_literal: true

require 'forwardable'
require_relative 'scorer/jury_bench'

module ActiveGenie
  module Scorer
    extend Forwardable

    module_function
    
    def_delegator :JuryBench, :call
    def_delegator :JuryBench, :call, :by_jury_bench
  end
end

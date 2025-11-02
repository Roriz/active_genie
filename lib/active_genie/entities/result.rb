# frozen_string_literal: true

module ActiveGenie
  class Result
    attr_reader :data, :reasoning, :metadata

    def initialize(data:, metadata:, reasoning: nil)
      @data = data
      @reasoning = reasoning
      @metadata = metadata
    end

    def explanation
      @reasoning
    end

    def to_h
      { data: @data, reasoning: @reasoning, metadata: @metadata }
    end

    def to_s
      to_h.to_s
    end

    def to_json(...)
      to_h.to_json(...)
    end
  end
end

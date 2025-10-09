# frozen_string_literal: true

module ActiveGenie
  class Response
    attr_reader :data, :reasoning, :raw

    def initialize(data:, raw:, reasoning: nil)
      @data = data
      @reasoning = reasoning
      @raw = raw
    end

    def to_h
      { data: @data, reasoning: @reasoning, raw: @raw }
    end

    def to_s
      to_h.to_s
    end

    def to_json(...)
      to_h.to_json(...)
    end
  end
end

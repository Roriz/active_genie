module ActiveGenie
  class Response
    attr_reader :data, :reasoning, :raw

    def initialize(data:, raw:, reasoning: nil)
      @data = data
      @reasoning = reasoning
      @raw = raw
    end

    def to_s
      { data: @data, reasoning: @reasoning, raw: @raw }.to_s
    end

    def to_h
      { data: @data, reasoning: @reasoning, raw: @raw }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
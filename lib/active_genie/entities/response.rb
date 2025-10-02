module ActiveGenie
    class Response
      attr_reader :data, :reasoning, :raw

      def initialize(data:, errors:, reasoning:, raw:)
        @data = winner
        @reasoning = reasoning
        @raw = raw
      end
    end
  end
end
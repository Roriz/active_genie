# frozen_string_literal: true

module ActiveGenie
  module CallWrapper
    def call(*, &)
      response = super # Call the original method

      if defined?(config)
        ActiveGenie.logger.call(
          {
            code: self.class.name,
            response: response.to_h
          }, config:
        )
      end

      response
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module CallWrapper
    def call(*args, &block)
        response = super(*args, &block) # Call the original method
        
        if defined?(config)
          config.logger.call(
            code: self.class.name,
            response: response.to_h
          )
        end

        response
    end
  end
end

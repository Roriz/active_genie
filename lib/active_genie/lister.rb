# frozen_string_literal: true

require_relative 'factory/feud'

module ActiveGenie
  module Factory
    module_function

    def feud(...)
      Feud.call(...)
    end

    def list(...)
      Feud.call(...)
    end

    def call(...)
      Feud.call(...)
    end
  end
end

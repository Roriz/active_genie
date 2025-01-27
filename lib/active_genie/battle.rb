
require_relative 'battle/basic'

module ActiveGenie
  # Battle module
  module Battle
    module_function

    def basic(...)
      Basic.call(...)
    end
  end
end

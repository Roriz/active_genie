
require_relative 'battle/basic'

module ActiveGenie
  # See the [Battle README](lib/active_genie/battle/README.md) for more information.
  module Battle
    module_function

    def basic(...)
      Basic.call(...)
    end
  end
end

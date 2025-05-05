# frozen_string_literal: true

require_relative 'battle/generalist'

module ActiveGenie
  # See the [Battle README](lib/active_genie/battle/README.md) for more information.
  module Battle
    module_function

    def call(...)
      Generalist.call(...)
    end

    def generalist(...)
      Generalist.call(...)
    end
  end
end

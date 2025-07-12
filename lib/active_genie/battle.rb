# frozen_string_literal: true

require_relative 'battle/generalist'
require_relative 'battle/fight'

module ActiveGenie
  # See the [Battle README](lib/active_genie/battle/README.md) for more information.
  module Battle
    module_function

    def generalist(...)
      Generalist.call(...)
    end

    def call(...)
      Generalist.call(...)
    end

    def compare(...)
      Generalist.call(...)
    end

    def fight(...)
      Fight.call(...)
    end
  end
end

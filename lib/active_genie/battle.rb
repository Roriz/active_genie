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
    alias_method :compare, :generalist
    alias_method :call, :generalist

    def fight(...)
      Fight.call(...)
    end
  end
end

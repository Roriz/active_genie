# frozen_string_literal: true

require_relative 'lister/feud'
require_relative 'lister/juries'

module ActiveGenie
  module Lister
    module_function

    def call(...)
      Feud.call(...)
    end
    def with_feud(...)
      Feud.call(...)
    end
    def with_juries(...)
      Juries.call(...)
    end

  end
end

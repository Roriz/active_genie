# frozen_string_literal: true

require_relative 'data_extractor/generalist'
require_relative 'data_extractor/from_informal'

module ActiveGenie
  # See the [DataExtractor README](lib/active_genie/data_extractor/README.md) for more information.
  module DataExtractor
    module_function

    def call(...)
      Generalist.call(...)
    end

    def generalist(...)
      Generalist.call(...)
    end

    def from_informal(...)
      FromInformal.call(...)
    end
  end
end

require_relative 'data_extractor/basic'
require_relative 'data_extractor/from_informal'

module ActiveGenie
  # See the [DataExtractor README](lib/active_genie/data_extractor/README.md) for more information.
  module DataExtractor
    module_function

    def basic(...)
      Basic.call(...)
    end

    def from_informal(...)
      FromInformal.call(...)
    end
  end
end

require_relative 'data_extractor/basic'
require_relative 'data_extractor/from_informal'

module ActiveGenie
  # Extract structured data from text using AI-powered analysis, handling informal language and complex expressions.
  module DataExtractor
    module_function

    def basic(*args)
      Basic.call(*args)
    end

    def from_informal(*args)
      FromInformal.call(*args)
    end
  end
end

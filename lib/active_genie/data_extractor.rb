require_relative 'data_extractor/basic'
require_relative 'data_extractor/from_informal'

module ActiveGenie
  # The DataExtractor module handles the extraction of structured data from text inputs
  # using AI models through function calling.
  module DataExtractor
    module_function

    def basic(text, data_to_extract, options: {})
      Basic.call(text, data_to_extract, options:)
    end

    def from_informal(text, data_to_extract, options: {})
      FromInformal.call(text, data_to_extract, options:)
    end
  end
end

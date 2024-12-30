
require_relative 'active_ai/data_extractor/data_extractor.rb'

module ActiveAI
  module_function

  def data_extractor(text, data_to_extract)
    DataExtrator.call(text, data_to_extract)
  end
end

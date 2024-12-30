
require_relative 'active_generative/data_extractor/data_extractor.rb'

module ActiveGenerative
  module_function

  def data_extractor(text, data_to_extract)
    DataExtrator.call(text, data_to_extract)
  end
end

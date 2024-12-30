
require_relative 'active_generative/requester'
require_relative 'active_generative/data_extractor'

module ActiveGenerative
  attr_writer :default_model

  module_function

  def data_extractor(text, data_to_extract)
    DataExtrator.call(text, data_to_extract)
  end
end

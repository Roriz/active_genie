# frozen_string_literal: true

require 'debug'
require 'minitest/autorun'
require_relative '../../lib/active_genie'

ActiveGenie.configure do |config|
  config.providers.default = ENV['PROVIDER']
  config.llm.model = ENV['MODEL']
end

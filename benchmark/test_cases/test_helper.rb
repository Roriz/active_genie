require 'debug'
require "minitest/autorun"
require_relative "../../lib/active_genie"

ActiveGenie.configure do |config|
  config.log.log_level = -1
  config.runtime.model = ENV['MODEL']
  config.runtime.provider = ENV['PROVIDER']
  config.runtime.api_key = ENV['API_KEY']
end

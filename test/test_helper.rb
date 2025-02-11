require 'debug'
require "minitest/autorun"
require_relative "../lib/active_genie"

ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']

  config.log.log_level = nil
end
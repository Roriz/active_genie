require 'debug'
require "minitest/autorun"
require_relative "../lib/active_genie"

ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  config.providers.google.api_key = ENV['GENERATIVE_LANGUAGE_GOOGLE_API_KEY']

  config.log.log_level = -1
end
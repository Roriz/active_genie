# frozen_string_literal: true

require 'debug'
require 'minitest/autorun'
require_relative '../../lib/active_genie'

ActiveGenie.configure do |config|
  config.providers.default = ENV.fetch('PROVIDER_NAME', nil)
  config.llm.model = ENV.fetch('MODEL', nil)

  config.log.output = ->(log) {}
end

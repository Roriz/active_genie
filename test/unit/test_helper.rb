# frozen_string_literal: true

require 'debug'
require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../../lib/active_genie'

ActiveGenie.configure do |config|
  include WebMock::API

  config.log.output = ->(log) {}
end

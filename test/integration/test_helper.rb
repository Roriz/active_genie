# frozen_string_literal: true

require 'bundler' # the tests call Bundler.with_unbundled_env; plain `rake` doesn't load it
require 'debug'
require 'minitest/autorun'

require_relative '../../lib/active_genie'

ActiveGenie.configure do |config|
  config.log.output = ->(log) {}
end

# frozen_string_literal: true

require 'debug'
require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../lib/active_genie'

include WebMock::API

ActiveGenie.configure do |config|
  # Do not configure providers here
end

# Minitest.before do
#   ActiveGenie.configure.providers.all.each do |provider_name, provider|
#     fixture_path = "test/fixtures/#{provider_name}.json"
#     puts "Stubbing #{provider_name} with #{fixture_path}"
#     puts provider.api_url
#     stub_request(:post, /#{provider.api_url}.*$/).to_return(status: 200, body: File.read(fixture_path))
#   end
# end


# Minitest.after_run do
#   WebMock.reset!
# end

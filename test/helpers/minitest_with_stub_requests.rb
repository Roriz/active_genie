# frozen_string_literal: true

require_relative '../test_helper'
require 'webmock/minitest'

module ActiveGenie
  class MinitestWithStubRequests < Minitest::Test
    def setup
      ActiveGenie.configuration.providers.all.each do |provider_name, provider|
        fixture_path = "test/fixtures/#{provider_name}.json"
        stub_request(:post, /#{provider.api_url}.*$/).to_return(status: 200, body: File.read(fixture_path))
      end
    end
  end
end

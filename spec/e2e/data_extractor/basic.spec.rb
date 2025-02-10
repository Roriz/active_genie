# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  gem "active_genie", path: File.join(__dir__, '../../..')

  gem 'minitest'
end

require "minitest/autorun"
require "active_genie"

ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']

  config.log.log_level = nil
end

class ActiveGenie::DataExtractor::BasicTest < Minitest::Test
  def test_simple_extraction
    result = ActiveGenie::DataExtractor::Basic.call(
      "Hi my name is Roriz",
      { name: { type: 'string' } }
    )

    assert_equal "Roriz", result['name']
  end
end
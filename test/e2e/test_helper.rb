# frozen_string_literal: true

require 'json'
require 'debug'
require 'minitest/autorun'
require_relative '../../lib/active_genie'

provider_name = ENV.fetch('PROVIDER_NAME', 'openai').to_s.downcase.strip

REQUIRED_ENV_KEYS = {
  'openai' => ['OPENAI_API_KEY'],
  'anthropic' => ['ANTHROPIC_API_KEY'],
  'google' => %w[GENERATIVE_LANGUAGE_GOOGLE_API_KEY GEMINI_API_KEY],
  'deepseek' => ['DEEPSEEK_API_KEY']
}.freeze

DEFAULT_E2E_MODELS = {
  'openai' => 'gpt-5.6-luna',
  'anthropic' => 'claude-haiku-4-5',
  'google' => 'gemini-3.5-flash-lite',
  'deepseek' => 'deepseek-v4-flash'
}.freeze

keys = REQUIRED_ENV_KEYS[provider_name]
if keys
  has_key = keys.any? { |key| ENV[key] && !ENV[key].strip.empty? }
  unless has_key
    raise "E2E Test Failure: Missing API key for provider '#{provider_name}'. " \
          "Please set #{keys.join(' or ')} in your environment."
  end
else
  raise "E2E Test Failure: Unknown provider '#{provider_name}'. " \
        "Supported providers are: #{REQUIRED_ENV_KEYS.keys.join(', ')}"
end

selected_model = ENV['MODEL'] || DEFAULT_E2E_MODELS[provider_name]

ActiveGenie.configure do |config|
  config.providers.default = provider_name
  config.llm.model = selected_model
  config.log.output = ->(_log) {}
end

module E2EFixtureHelper
  def load_fixture(relative_path)
    fixture_path = File.join(__dir__, 'fixtures', relative_path)
    unless File.exist?(fixture_path)
      raise "Fixture file not found: #{fixture_path}"
    end

    content = File.read(fixture_path)
    if relative_path.end_with?('.json')
      JSON.parse(content, symbolize_names: true)
    else
      content
    end
  end
end

class Minitest::Test
  include E2EFixtureHelper
end

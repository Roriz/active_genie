require 'debug'
require_relative '../lib/active_genie.rb'

ActiveGenie.configure do |config|
  config.path_to_config = File.join(__dir__, 'active_genie.yml')
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end

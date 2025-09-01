# frozen_string_literal: true

ActiveGenie.configure do |config|
  # example with openai and the current default for each config
  # config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  # config.providers.openai.organization = ENV['OPENAI_ORGANIZATION']
  # config.providers.openai.api_url = 'https://api.openai.com/v1'
  # config.providers.openai.client = ActiveGenie::Providers::Openai::Client.new(config)

  # example how add a new provider
  # config.providers.add(InternalCompanyApi::Configuration)

  # Logs configuration
  # config.log.log_level = :debug # default is :info
  # config.log.add_observer(GlobalLogObserver.new)
  # config.log.add_observer(PersistUsageObserver.new, scope: { code: 'llm_usage' })
  # config.log.remove_observer(PersistUsageObserver.new)
  # config.log.clear_observers
end

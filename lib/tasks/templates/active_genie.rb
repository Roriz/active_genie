
ActiveGenie.configure do |config|
  # example with openai and the current default for each config
  # config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  # config.providers.openai.organization = ENV['OPENAI_ORGANIZATION']
  # config.providers.openai.api_url = 'https://api.openai.com/v1'
  # config.providers.openai.lower_tier_model = 'gpt-4o-mini'
  # config.providers.openai.middle_tier_model = 'gpt-4o'
  # config.providers.openai.upper_tier_model = 'o1-preview'
  # config.providers.openai.client = ActiveGenie::Providers::Openai::Client.new(config)

  # example how add a new provider
  # config.providers.register(InternalCompanyApi::Configuration)

  # Logs configuration
  # config.log_level = :debug # default is :info
end
# frozen_string_literal: true

ActiveGenie.configure do |config|
  # Providers: set a key for each one you use (defaults shown)
  # config.providers.openai.api_key = ENV['OPENAI_API_KEY']
  # config.providers.openai.organization = ENV['OPENAI_ORGANIZATION']
  # config.providers.openai.api_url = 'https://api.openai.com/v1'
  # config.providers.default = 'openai' # skip it to let each module pick

  # Replace a built-in provider's config (e.g. an OpenAI-compatible gateway), or drop one
  # config.providers.add(:openai, MyGatewayConfig)
  # config.providers.remove(:deepseek)

  # Logs
  # config.log.output = ->(log) { Rails.logger.info(log) } # default prints to stdout
  # config.log.add_observer(observers: [GlobalLogObserver.new])
  # config.log.add_observer(observers: [PersistUsageObserver.new], scope: { code: :llm_usage })
  # config.log.remove_observer(PersistUsageObserver.new)
  # config.log.clear_observers
end

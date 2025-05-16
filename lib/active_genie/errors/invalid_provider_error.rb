
module ActiveGenie
  class InvalidProviderError < StandardError
    TEXT = <<~TEXT
      Invalid provider: %<provider>s

      To configure ActiveGenie, you can either:
      1. Set up global configuration:
         ```ruby
         ActiveGenie.configure do |config|
           config.provider = 'your_provider'
           config.api_key = 'your_api_key'
           # ... other configuration options
         end
         ```

      2. Or pass configuration directly to the method call:
         ```ruby
         ActiveGenie::DataExtraction.call(
           arg1,
           arg2,
           config: {
             provider: 'your_provider',
             api_key: 'your_api_key'
           }
         )
         ```

      Available providers: %<available_providers>s
    TEXT

    def initialize(provider)
      super(TEXT % {
        provider:,
        available_providers:
      })
    end

    def available_providers
      ActiveGenie.configuration.providers.all.keys.join(', ')
    end
  end
end

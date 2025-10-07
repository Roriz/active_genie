# frozen_string_literal: true

module ActiveGenie
  class WithoutAvailableProviderError < StandardError
    TEXT = <<~TEXT
      Missing at least one credentialed provider to proceed.

      To configure ActiveGenie, you can either:
      1. Set up global configuration:
         ```ruby
         ActiveGenie.configure do |config|
           config.providers.default = 'openai'
           config.providers.openai.api_key = 'your_api_key'
           # ... other configuration options
         end
         ```

      2. Or pass configuration directly to the method call:
         ```ruby
         ActiveGenie::Extractor.call(
           arg1,
           arg2,
           config: {
             providers: {
               default: 'openai',
               openai: {
                 api_key: 'your_api_key'
               }
             }
           }
         )
         ```
    TEXT

    def initialize
      super(TEXT)
    end
  end
end

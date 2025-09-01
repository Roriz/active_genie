# frozen_string_literal: true

module ActiveGenie
  class InvalidModelError < StandardError
    TEXT = <<~TEXT
      Invalid model: %<model>s

      To configure ActiveGenie, you can either:
      1. Set up global configuration:
         ```ruby
         ActiveGenie.configure do |config|
          config.providers.openai.api_key = 'your_api_key'
           config.llm.model = 'gpt-5'
           # ... other configuration options
         end
         ```

      2. Or pass configuration directly to the method call:
         ```ruby
         ActiveGenie::Extraction.call(
           arg1,
           arg2,
           config: {
             providers: {
               openai: {
                 api_key: 'your_api_key'
               }
             },
             llm: {
               model: 'gpt-5'
             }
           }
         )
         ```

    TEXT

    def initialize(model)
      super(format(TEXT, model:))
    end
  end
end

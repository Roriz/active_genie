
## Installation

1. Add to your Gemfile:
```ruby
gem 'active_genie'
```

2. Install the gem:
```shell
bundle install
```

3. Generate the configuration:
```shell
echo "ActiveGenie.load_tasks" >> Rakefile
rails g active_genie:install
```

4. Configure your credentials in `config/initializers/active_genie.rb`:
```ruby
ActiveGenie.configure do |config|
  config.providers.openai.api_key = ENV['OPENAI_API_KEY']
end
```

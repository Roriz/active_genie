# frozen_string_literal: true

require_relative 'test_helper'

module ActiveGenie
  class RailsTest < Minitest::Test
    def setup
      @rails_app_path = '/tmp/latest_rails_app'
      system("rm -rf #{@rails_app_path}")
      system("rails new #{@rails_app_path} --skip-bundle --minimal")
      system("echo \"gem 'active_genie'\" >> #{@rails_app_path}/Gemfile")
      system("cd #{@rails_app_path} && bundle install --gemfile=Gemfile --path=vendor/bundle")
      system("echo \"ActiveGenie.load_tasks\" >> #{@rails_app_path}/Rakefile")
    end

    def test_latest_rails_version
      output = `cd #{@rails_app_path} && rails active_genie:install`

      assert_match(/Successfully installed active_genie!\n/, output)
      assert_path_exists "#{@rails_app_path}/config/initializers/active_genie.rb", 'Initializer file not created'
    end
  end
end

# frozen_string_literal: true

require_relative 'test_helper'

module ActiveGenie
  class RailsTest < Minitest::Test
    def setup
      @rails_app_path = '/tmp/latest_rails_app'
      Bundler.with_unbundled_env do
        system("rm -rf #{@rails_app_path}")
        system("rails new #{@rails_app_path} --skip-bundle --minimal")
        system("echo \"gem 'active_genie', path: '#{File.expand_path('../..', __dir__)}'\" >> #{@rails_app_path}/Gemfile")
        system("cd #{@rails_app_path} && bundle install")
        system("echo \"ActiveGenie.load_tasks\" >> #{@rails_app_path}/Rakefile")
      end
    end

    def test_latest_rails_version
      output = Bundler.with_unbundled_env do
        `cd #{@rails_app_path} && rails active_genie:install`
      end

      assert_match(/Successfully installed active_genie!\n/, output)
      assert_path_exists "#{@rails_app_path}/config/initializers/active_genie.rb", 'Initializer file not created'
    end

    def test_scaffolds_an_eval_that_passes_the_free_check
      output = Bundler.with_unbundled_env do
        `cd #{@rails_app_path} && bin/rails "active_genie:eval:new[ticket_router]" && bin/rails active_genie:eval:check 2>&1`
      end

      assert_path_exists "#{@rails_app_path}/evals/ticket_router/eval.rb"
      assert_path_exists "#{@rails_app_path}/evals/README.md"
      assert_match(/check passed/, output)
    end
  end
end

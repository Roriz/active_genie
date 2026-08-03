# frozen_string_literal: true

require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.pattern = 'test/unit/**/*_test.rb'
  end
  desc 'Run unit tests'
  task unit: :reset_env

  Rake::TestTask.new(:integration) do |t|
    t.pattern = 'test/integration/**/*_test.rb'
  end
  desc 'Run integration tests like install rails'
  task integration: :reset_env

  Rake::TestTask.new(:e2e) do |t|
    t.pattern = 'test/e2e/**/*_test.rb'
    t.warning = false
  end
  desc 'Run E2E live tests for specified provider (PROVIDER_NAME=openai by default)'
  task e2e: :check_e2e_env

  namespace :e2e do
    desc 'Run E2E live tests sequentially across all supported providers (openai, anthropic, google, deepseek)'
    task :all do
      providers = %w[openai anthropic google deepseek]
      providers.each do |provider|
        puts "\n#{'=' * 60}"
        puts "  Running E2E Suite for Provider: #{provider.upcase}"
        puts '=' * 60
        system("PROVIDER_NAME=#{provider} bundle exec rake test:e2e") || raise("E2E tests failed for provider: #{provider}")
      end
    end
  end

  desc 'Run all tests (unit and integration)'
  task default: %i[unit integration]

  desc 'Reset environment variables for API keys'
  task :reset_env do
    reset_environment_variables
  end

  task :check_e2e_env do
    provider = ENV.fetch('PROVIDER_NAME', 'openai').to_s.downcase.strip
    required_keys = {
      'openai' => ['OPENAI_API_KEY'],
      'anthropic' => ['ANTHROPIC_API_KEY'],
      'google' => %w[GENERATIVE_LANGUAGE_GOOGLE_API_KEY GEMINI_API_KEY],
      'deepseek' => ['DEEPSEEK_API_KEY']
    }
    keys = required_keys[provider]
    if keys
      has_key = keys.any? { |k| ENV[k] && !ENV[k].strip.empty? }
      unless has_key
        raise "E2E Test Error: Missing API key for provider '#{provider}'. Please set #{keys.join(' or ')} in environment."
      end
    end
  end
end

desc 'Run all tests (unit and integration) or a specific test file'
task :test, [:file_path] do |_t, args|
  if args[:file_path]
    file_path, line_number = args[:file_path].split(':')

    if file_path.start_with?('test/e2e')
      # Do not reset env vars for e2e tests
      Rake::Task['test:check_e2e_env'].invoke
    else
      reset_environment_variables
    end

    if line_number
      test_name = find_test_name_at_line(file_path, line_number.to_i)

      if test_name
        sh "ruby -Itest #{file_path} --name #{test_name}"
      else
        puts "Warning: Could not find test method at line #{line_number}"
        ruby "-Itest #{file_path}"
      end
    else
      ruby "-Itest #{file_path}"
    end
  else
    reset_environment_variables
    Rake::Task['test:unit'].invoke
    Rake::Task['test:integration'].invoke
  end
end

def find_test_name_at_line(file_path, line_number)
  return nil unless File.exist?(file_path)

  lines = File.readlines(file_path)
  return nil if line_number > lines.length

  (line_number - 1).downto(0) do |i|
    line = lines[i]
    if line =~ /^\s*def\s+(test_\w+)/
      return Regexp.last_match(1)
    elsif line =~ /^\s*test\s+['"](.+?)['"]\s+do/
      test_desc = Regexp.last_match(1)
      return "/#{test_desc}/"
    end
  end

  nil
end

def reset_environment_variables
  ENV['OPENAI_API_KEY'] = nil
  ENV['GEMINI_API_KEY'] = nil
  ENV['ANTHROPIC_API_KEY'] = nil
  ENV['DEEPSEEK_API_KEY'] = nil
end

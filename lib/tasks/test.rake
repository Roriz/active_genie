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

  desc 'Run all tests (unit and integration)'
  task default: %i[unit integration]

  desc 'Reset environment variables for API keys'
  task :reset_env do
    reset_environment_variables
  end
end

desc 'Run all tests (unit and integration) or a specific test file'
task :test, [:file_path] do |_t, args|
  reset_environment_variables

  if args[:file_path]
    file_path, line_number = args[:file_path].split(':')

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

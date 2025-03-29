# frozen_string_literal: true

require "rake/testtask"

Dir.glob('lib/tasks/**/*.rake').each { |r| load r }

desc "Run tests, optionally from a specific folder (e.g., rake test[test/unit])"
task :test, [:folder_path] do |_, args|
  Rake::TestTask.new(:run_tests) do |t|
    t.libs << "test"
    
    if args[:folder_path]
      folder_path = args[:folder_path]
      # Ensure the path ends with a slash for proper globbing
      folder_path = "#{folder_path}/" unless folder_path.end_with?('/')
      t.test_files = FileList["#{folder_path}**/*_test.rb"]
      puts "Running tests from: #{folder_path}"
    else
      t.test_files = FileList["test/**/*_test.rb"]
      puts "Running all tests"
    end
    
    t.warning = false
  end
  
  begin
    Rake::Task[:run_tests].invoke
  rescue => e
    puts e
  end
end

task default: :test
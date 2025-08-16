# frozen_string_literal: true

namespace :active_genie do
  desc 'Run benchmarks, optionally for a specific module (e.g., rake active_genie:benchmark[data_extractor])'
  task :benchmark, [:module_name] do |_, args|
    Rake::TestTask.new(:run_benchmarks) do |t|
      if args[:module_name]
        module_name = args[:module_name]
        module_path = "test/benchmark/#{module_name}/"
        t.test_files = FileList["#{module_path}**/*_test.rb"]
        puts "Running benchmarks for module: #{module_name}"
      else
        t.test_files = FileList['benchmark/test_cases/**/*_test.rb']
        puts 'Running all benchmarks'
      end

      t.warning = false
    end

    begin
      Rake::Task[:run_benchmarks].invoke
    rescue StandardError => e
      puts e
    end
  end
end

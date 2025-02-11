# frozen_string_literal: true

require "rake/testtask"

Dir.glob('lib/tasks/**/*.rake').each { |r| load r }

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

task default: :test
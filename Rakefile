# frozen_string_literal: true

require "rake/testtask"

desc "Default Task"
task default: [ :test ]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

Dir.glob('lib/tasks/**/*.rake').each { |r| load r }

# frozen_string_literal: true

require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.pattern = 'test/unit/**/*_test.rb'
  end

  Rake::TestTask.new(:integration) do |t|
    t.pattern = 'test/integration/**/*_test.rb' # Or use _spec.rb for RSpec
  end

  task default: %i[unit integration]
end

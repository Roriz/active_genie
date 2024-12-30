require 'fileutils'

namespace :active_ai do
  desc 'Install active_ai configuration file'
  task :install do
    source = File.join('lib', 'tasks', 'templates', 'active_ai.yml')
    target = File.join('config', 'active_ai.yml')

    FileUtils.cp(source, target)
    puts "Successfully installed active_ai.yml to #{target}"
  end
end

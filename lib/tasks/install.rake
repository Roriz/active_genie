require 'fileutils'

namespace :active_generative do
  desc 'Install active_generative configuration file'
  task :install do
    source = File.join('lib', 'tasks', 'templates', 'active_generative.yml')
    target = File.join('config', 'active_generative.yml')

    FileUtils.cp(source, target)
    puts "Successfully installed active_generative.yml to #{target}"
  end
end

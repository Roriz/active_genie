require 'fileutils'

namespace :active_ai do
  desc 'Install active_ai configuration file'
  task :install do
    source = File.join('lib', 'tasks', 'templates', 'genai.yml')
    target = File.join('config', 'genai.yml')

    FileUtils.cp(source, target)
    puts "Successfully installed genai.yml to #{target}"
  end
end

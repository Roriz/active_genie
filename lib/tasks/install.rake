require 'fileutils'

namespace :active_genie do
  desc 'Install active_genie configuration file'
  task :install do
    source = File.join(__dir__, 'templates', 'active_genie.yml')
    target = File.join('config', 'active_genie.yml')

    FileUtils.cp(source, target)
    puts "Successfully installed config/active_genie.yml to #{target}"
  end
end

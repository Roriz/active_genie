require 'fileutils'

namespace :active_genie do
  desc 'Install active_genie configuration file'
  task :install do
    source = File.join(__dir__, 'templates', 'active_genie.rb')
    target = File.join('config', 'initializers', 'active_genie.rb')

    FileUtils.cp(source, target)
    puts "Successfully installed active_genie!"
  end
end

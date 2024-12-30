require 'rake'

RSpec.describe 'active_ai:install task' do
  let(:target_path) { File.join('config', 'active_ai.yml') }

  before(:each) do
    load File.expand_path("../../lib/tasks/install.rake", __dir__)
    Rake::Task.define_task(:environment)
    
    FileUtils.mkdir_p('config')
  end

  after(:each) do
    FileUtils.rm_f(target_path)
    FileUtils.rm_rf('config')
  end

  it 'copies the configuration file to the target location' do
    Rake::Task['active_ai:install'].invoke
    expect(File.exist?(target_path)).to be true
  end
end

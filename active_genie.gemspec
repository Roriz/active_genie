# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'active_genie'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.summary       = 'Transform your Ruby application with powerful, production-ready GenAI features'
  spec.description   = <<~DESC
    The lodash for GenAI, stop reinventing the wheel

    ActiveGenie is a Ruby gem that provides valuable solutions using GenAI. Just like Lodash or ActiveStorage, ActiveGenie brings a set of Modules to reach real value fast and reliably. Backed by a custom benchmarking system that ensures consistent quality and performance across different models and providers in every release.
  DESC
  spec.authors       = ['Radamés Roriz']
  spec.email         = ['radames@roriz.dev']

  spec.required_ruby_version = '>= 3.4.0'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/Roriz/active_genie',
    'documentation_uri' => 'https://github.com/Roriz/active_genie/wiki',
    'changelog_uri' => 'https://github.com/Roriz/active_genie/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/Roriz/active_genie/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = Dir['{lib,ext}/**/*', 'VERSION', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.homepage      = 'https://github.com/Roriz/active_genie'
  spec.license       = 'Apache-2.0'
end

# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'active_genie'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.summary       = 'The Lodash for GenAI: Real Value + Consistent + Model-Agnostic'
  spec.description   = <<~DESC
    ActiveGenie is a Ruby gem that helps developers build reliable, future-proof GenAI features without worrying about changing models, prompts, or providers. Like Lodash for GenAI, it offers simple, reusable modules for tasks like extractor, comparator, scorer, and ranker, so you can focus on your app’s logic, not the shifting AI landscape.
    Behind the scenes, a custom benchmarking system keeps everything consistent across LLM vendors and versions, release after release.
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

  spec.add_dependency 'async', '>= 2.0'

  spec.homepage      = 'https://github.com/Roriz/active_genie'
  spec.license       = 'Apache-2.0'
end

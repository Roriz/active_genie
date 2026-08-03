# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'active_genie'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.summary       = 'The Lodash for GenAI: Consistent + Model-Agnostic'
  spec.description   = <<~DESC
    ActiveGenie is a toolkit for building reliable GenAI features in Ruby, with model-agnostic modules that work across providers. It allows you to settle subjective comparisons with an `ActiveGenie::Comparator` module that stages a structured debate, get accurate scores from an AI jury using `ActiveGenie::Scorer`, and rank large datasets using `ActiveGenie::Ranker`'s tournament-style system.
    This reliability is built on three core pillars:
    - Custom Benchmarking: Testing for consistency with every new version and model update.
    - Reasoning Prompting: Utilizing human reasoning techniques (like debate and jury review) to control a model's reasoning.
    - Overfitting Prompts: Highly specialized, and potentially model-specific, prompt for each module's purpose.
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

  spec.add_dependency 'async', '~> 2.0'

  spec.homepage      = 'https://github.com/Roriz/active_genie'
  spec.license       = 'Apache-2.0'
end

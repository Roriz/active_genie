version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = "active_genie"
  spec.version       = version
  spec.summary       = "Modules and classes to help you build AI features, like data extraction, summarization, scoring, and ranking."
  spec.description   = <<-DESC
    ActiveGenie provides a robust toolkit for integrating AI capabilities into Ruby applications.
    Features include:
    * Structured data extraction from text
    * Smart text summarization
    * Content scoring and ranking
    * AI-powered classification
  DESC
  spec.authors       = ["Radamés Roriz"]
  spec.email         = ["radames@roriz.dev"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.metadata = {
    "homepage_uri"      => "https://github.com/Roriz/active_genie",
    "documentation_uri" => "https://github.com/Roriz/active_genie/wiki",
    "changelog_uri"     => "https://github.com/Roriz/active_genie/blob/master/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/Roriz/active_genie",
    "bug_tracker_uri"   => "https://github.com/Roriz/active_genie/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["lib/**/*", "VERSION", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.homepage      = "https://github.com/Roriz/active_genie"
  spec.license       = "Apache-2.0"
end

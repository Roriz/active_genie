version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = "active_genie"
  spec.version       = version
  spec.summary       = "Transform your Ruby application with powerful, production-ready GenAI features"
  spec.description   = File.read(File.expand_path("README.md", __dir__))
  spec.authors       = ["Radamés Roriz"]
  spec.email         = ["radames@roriz.dev"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "homepage_uri"      => "https://github.com/Roriz/active_genie",
    "documentation_uri" => "https://github.com/Roriz/active_genie/wiki",
    "changelog_uri"     => "https://github.com/Roriz/active_genie/blob/master/CHANGELOG.md",
    "bug_tracker_uri"   => "https://github.com/Roriz/active_genie/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["{lib,ext}/**/*", "VERSION", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.homepage      = "https://github.com/Roriz/active_genie"
  spec.license       = "Apache-2.0"
end

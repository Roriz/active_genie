version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  s.platform         = Gem::Platform::RUBY
  spec.name          = "active_ai"
  spec.version       = version
  spec.summary       = "Modules and classes to help you build AI features, like data extraction, summarization, scoring, and ranking."
  spec.authors       = ["Radamés Roriz"]

  spec.files         = ["lib/active_ai.rb"]
  spec.require_paths = ["lib"]

  spec.homepage      = "https://github.com/Roriz/active_ai"

  spec.license       = "Apache-2.0"
end

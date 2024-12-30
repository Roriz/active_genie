version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  s.platform         = Gem::Platform::RUBY
  spec.name          = "active_generative"
  spec.version       = version
  spec.summary       = "Modules and classes to help you build generative features"
  spec.authors       = ["Radamés Roriz"]

  spec.files         = ["lib/active_generative.rb"]
  spec.require_paths = ["lib"]

  spec.license       = "Apache-2.0"
end

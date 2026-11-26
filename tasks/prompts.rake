# frozen_string_literal: true

require 'json'

# The gem's own prompt files, checked for free: no model call. Not shipped with the gem (apps lint
# their own prompts their own way); the lint CI workflow runs it.
namespace :prompts do
  desc 'Free: lint lib/**/*.prompt.md and the function JSON, and list what changed in lib/ vs main'
  task :check do
    lib = File.expand_path('../lib/active_genie', __dir__)
    errors = []
    mojibake = /Ã.|â€|ï»¿|�/
    Dir.glob(File.join(lib, '**', '*.prompt.md')).each do |file|
      text = File.read(file, encoding: 'UTF-8')
      errors << "#{file}: empty prompt" if text.strip.empty?
      errors << "#{file}: mojibake (broken encoding)" if text.match?(mojibake)
    rescue ArgumentError => e
      errors << "#{file}: #{e.message}"
    end
    Dir.glob(File.join(lib, '{comparator,extractor,lister,scorer}', '*.json')).each do |file|
      JSON.parse(File.read(file))
    rescue JSON::ParserError => e
      errors << "#{file}: invalid JSON (#{e.message.lines.first.strip})"
    end

    # A shallow CI checkout has no local main: say so instead of claiming lib/ matches it.
    if `git rev-parse --verify --quiet main 2>/dev/null`.strip.empty?
      puts 'lib/ vs main: skipped, no local main branch here'
    else
      changed = `git diff --name-only main -- lib 2>/dev/null`.split("\n") |
                `git ls-files --others --exclude-standard -- lib 2>/dev/null`.split("\n")
      puts changed.empty? ? 'lib/ matches main' : "lib/ changed vs main: #{changed.sort.join(', ')}"
    end
    errors.each { |e| puts "ERROR #{e.delete_prefix("#{File.dirname(lib, 2)}/")}" }
    abort "prompts:check failed: #{errors.size} error(s)" if errors.any?
    puts 'prompts:check passed'
  end
end

# frozen_string_literal: true

require 'json'
require 'digest'
require 'fileutils'
require 'time'

# Golden-set eval for ActiveGenie. See eval/README.md.
module GenieEval
  ROOT = File.expand_path('..', __dir__)
  REPO = File.expand_path('..', ROOT)

  class Error < StandardError; end

  # The data root (eval/). Tests point it at a temporary copy.
  def self.root
    @root || ROOT
  end

  def self.root=(dir)
    @root = dir
    @config = nil
    Store.reset!
  end

  def self.path(*parts)
    File.join(root, *parts)
  end

  # Output of a git command run at the repo root ('' when git fails).
  def self.git(*args)
    IO.popen(['git', *args], chdir: REPO, err: File::NULL, &:read).to_s.strip
  end

  def self.config
    @config ||= JSON.parse(File.read(path('config.json')))
  end
end

require_relative 'genie_eval/store'
require_relative 'genie_eval/system'
require_relative 'genie_eval/selection'
require_relative 'genie_eval/matchers'
require_relative 'genie_eval/graders'
require_relative 'genie_eval/stats'
require_relative 'genie_eval/judge'
require_relative 'genie_eval/executor'
require_relative 'genie_eval/runner'
require_relative 'genie_eval/results'
require_relative 'genie_eval/scoreboard'
require_relative 'genie_eval/baseline'
require_relative 'genie_eval/check'
require_relative 'genie_eval/labeling'

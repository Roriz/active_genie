# frozen_string_literal: true

require 'erb'
require 'fileutils'

# Writes the starting files of evals/ into the app, from templates/eval/. It never overwrites a file
# that exists: once written, they are the app's to edit.
module ActiveGenieEvalInstall
  TEMPLATES = File.join(__dir__, 'templates', 'eval')
  NAME = /\A[a-z][a-z0-9_]*\z/

  module_function

  # The engine says where evals/ is (Rails.root, else the current directory).
  def eval_lib
    require_relative '../active_genie'
    require_relative '../active_genie/eval'
    ActiveGenie::Eval
  end

  # evals/config.yml, evals/README.md and evals/.gitignore.
  def install
    write('config.yml', read('config.yml'))
    write('README.md', read('README.md'))
    write('.gitignore', read('gitignore'))
  end

  # evals/<name>/eval.rb and a starting datasets.jsonl with example rows.
  def new_eval(name)
    abort "eval names are snake_case, like ticket_router (not #{name.inspect})" unless name.match?(NAME)

    install unless File.exist?(eval_lib.path('config.yml'))
    write(File.join(name, 'eval.rb'), eval_rb(name))
    write(File.join(name, 'datasets.jsonl'), read('datasets.jsonl'))
  end

  def eval_rb(name)
    class_name = name.split('_').map(&:capitalize).join
    ERB.new(read('eval.rb.erb'), trim_mode: '-').result_with_hash(name:, class_name:)
  end

  def read(template)
    File.read(File.join(TEMPLATES, template))
  end

  # `relative` is under evals/.
  def write(relative, content)
    file = eval_lib.path(relative)
    shown = file.delete_prefix("#{eval_lib.app_root}/")
    return puts("  exists  #{shown}") if File.exist?(file)

    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
    puts "  create  #{shown}"
  end
end

namespace :active_genie do
  namespace :eval do
    desc 'Write evals/config.yml, evals/README.md and evals/.gitignore (never overwrites)'
    task :install do
      ActiveGenieEvalInstall.install
    end

    desc 'Start a new eval: evals/<name>/eval.rb and a starting datasets.jsonl. Usage: active_genie:eval:new[name]'
    task :new, [:name] do |_t, args|
      name = args[:name] || ENV.fetch('EVAL') { abort 'Usage: rake "active_genie:eval:new[ticket_router]"' }
      ActiveGenieEvalInstall.new_eval(name)
    end
  end
end

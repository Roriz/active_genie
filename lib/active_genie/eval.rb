# frozen_string_literal: true

require 'json'
require 'yaml'
require 'digest'
require 'fileutils'
require 'time'

module ActiveGenie
  # Evals for your own LLM features: run your real code (prompt building, the LLM call, parsing) on
  # cases you keep in `evals/<name>/`, grade every answer against its gold, and compare each change
  # with a frozen baseline, with statistics that tell a real change from model noise.
  #
  # Your app owns the data (`evals/config.yml`, `evals/<name>/eval.rb`, its datasets, gold and
  # baselines); this module is the engine that runs it. Start with `rake active_genie:eval:install`
  # and `rake "active_genie:eval:new[name]"`, then read the README it writes into evals/.
  module Eval
    class Error < StandardError; end

    class << self
      attr_writer :app_root

      # The app's root folder: Rails.root in a Rails app, else the current directory.
      def app_root
        @app_root ||= if defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root
                        ::Rails.root.to_s
                      else
                        Dir.pwd
                      end
      end

      def root
        File.join(app_root, 'evals')
      end

      def path(*parts)
        File.join(root, *parts)
      end

      def config
        @config ||= begin
          file = path('config.yml')
          raise Error, 'evals/config.yml is missing; run `rake active_genie:eval:install`' unless File.exist?(file)

          YAML.safe_load_file(file) || {}
        rescue Psych::Exception => e
          raise Error, "evals/config.yml: #{e.message}"
        end
      end

      # Registers an eval. Called from evals/<name>/eval.rb, which `load!` reads.
      def define(name, &)
        dir = @loading || raise(Error, "define #{name} from evals/#{name}/eval.rb, which load! reads")
        name = name.to_s
        unless name == File.basename(dir)
          raise Error, "evals/#{File.basename(dir)}/eval.rb defines #{name.inspect}; name it after its folder"
        end

        definition = Definition.new(name:, dir:)
        Definition::Builder.new(definition).instance_eval(&)
        definitions[name] = definition
      end

      def definitions
        @definitions ||= {}
      end

      # Loads every evals/<name>/eval.rb, once.
      def load!
        return definitions if @loaded

        Dir.glob(path('*', 'eval.rb')).each do |file|
          @loading = File.dirname(file)
          load file
        ensure
          @loading = nil
        end
        @loaded = true
        definitions
      end

      def fetch(name)
        load!.fetch(name.to_s) do
          raise Error, "no eval #{name.inspect} in evals/ (evals: #{definitions.keys.sort.join(', ')})"
        end
      end

      # Forgets the loaded evals and config; tests point app_root at a temporary app.
      def reset!
        @config = nil
        @definitions = nil
        @loaded = false
        Judge.current = nil
      end

      def git(*args)
        IO.popen(['git', '-C', app_root, *args], err: File::NULL, &:read).to_s.strip
      rescue SystemCallError
        ''
      end
    end
  end
end

require_relative 'eval/definition'
require_relative 'eval/store'
require_relative 'eval/matchers'
require_relative 'eval/stats'
require_relative 'eval/judge'
require_relative 'eval/graders'
require_relative 'eval/system'
require_relative 'eval/selection'
require_relative 'eval/progress'
require_relative 'eval/runner'
require_relative 'eval/results'
require_relative 'eval/report'
require_relative 'eval/matrices'
require_relative 'eval/scoreboard'
require_relative 'eval/overview'
require_relative 'eval/baseline'
require_relative 'eval/labeling'
require_relative 'eval/check'
require_relative 'eval/scaffold'

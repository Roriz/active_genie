# frozen_string_literal: true

module ActiveGenie
  module Eval
    # What an eval runs against: an eval, a provider and model, and the exact contents of the files it
    # watches. Any change to those files gives a new hash, so outputs are never mixed across versions.
    class System
      attr_reader :definition, :provider, :model

      def self.from_env(definition, env = ENV)
        dev = Eval.config['dev'] || {} # `dev:` left with no value reads as nil
        new(definition:, provider: env.fetch('PROVIDER', dev['provider']), model: env.fetch('MODEL', dev['model']))
      end

      def initialize(definition:, provider:, model:)
        @definition = definition
        @provider = provider&.to_s
        @model = model&.to_s
      end

      def name
        [provider, model].compact.join('-').then { |n| n.empty? ? 'default' : n }
      end

      def code_hash
        @code_hash ||= begin
          digest = Digest::SHA256.new
          definition.watched_files.each do |file|
            digest << file << "\0" << File.binread(File.join(Eval.app_root, file)) << "\0"
          end
          digest << ActiveGenie::VERSION
          digest.hexdigest
        end
      end

      def run_root
        definition.path('runs', "#{name}-#{code_hash[0, 8]}")
      end

      def run_dir(replicate = 1)
        File.join(run_root, "r#{replicate}")
      end

      def replicates
        replicates_in(run_root)
      end

      def baseline_dir
        definition.path('baselines', name)
      end

      def baseline_replicates
        replicates_in(baseline_dir)
      end

      def git
        @git ||= begin
          files = definition.watched_files
          dirty = files.any? && !Eval.git('status', '--porcelain', '--', *files).empty?
          { 'sha' => Eval.git('rev-parse', 'HEAD'), 'branch' => Eval.git('rev-parse', '--abbrev-ref', 'HEAD'),
            'dirty' => dirty }
        end
      end

      def describe
        dirty = git['dirty'] ? ', watched files have uncommitted changes' : ''
        sha = git['sha'].to_s[0, 8]
        "#{definition.name} on #{provider || 'default provider'}/#{model || 'default model'} @ #{git['branch']} #{sha} " \
          "(code #{code_hash[0, 8]}#{dirty})"
      end

      private

      def replicates_in(dir)
        Dir.glob(File.join(dir, 'r*')).filter_map { |d| d[/r(\d+)\z/, 1]&.to_i }.sort
      end
    end
  end
end

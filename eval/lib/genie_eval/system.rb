# frozen_string_literal: true

module GenieEval
  # A system under test: provider + model + the exact contents of lib/.
  # A variant is a git commit, so the lib/ hash identifies the code being evaluated.
  class System
    attr_reader :provider, :model

    def self.dev
      new(**GenieEval.config.fetch('dev').transform_keys(&:to_sym))
    end

    def self.from_env(env = ENV)
      dev = GenieEval.config.fetch('dev')
      new(provider: env.fetch('PROVIDER', dev['provider']), model: env.fetch('MODEL', dev['model']))
    end

    def initialize(provider:, model:)
      @provider = provider.to_s
      @model = model.to_s
    end

    def name
      "#{provider}-#{model}"
    end

    # Content hash of every file under lib/, so uncommitted edits get their own runs.
    def lib_hash
      @lib_hash ||= begin
        digest = Digest::SHA256.new
        Dir.glob(File.join(REPO, 'lib', '**', '*')).select { |f| File.file?(f) }.sort.each do |file|
          digest << file.delete_prefix(REPO) << "\0" << File.binread(file) << "\0"
        end
        digest.hexdigest
      end
    end

    def run_root
      GenieEval.path('runs', "#{name}-#{lib_hash[0, 8]}")
    end

    def run_dir(replicate = 1)
      File.join(run_root, "r#{replicate}")
    end

    def replicates
      Dir.glob(File.join(run_root, 'r*')).filter_map { |d| d[/r(\d+)\z/, 1]&.to_i }.sort
    end

    def baseline_dir
      GenieEval.path('baselines', name)
    end

    def baseline_replicates
      Dir.glob(File.join(baseline_dir, 'r*')).filter_map { |d| d[/r(\d+)\z/, 1]&.to_i }.sort
    end

    def git
      @git ||= {
        'sha' => GenieEval.git('rev-parse', 'HEAD'),
        'branch' => GenieEval.git('rev-parse', '--abbrev-ref', 'HEAD'),
        'lib_dirty' => !GenieEval.git('status', '--porcelain', '--', 'lib').empty?
      }
    end

    def describe
      dirty = git['lib_dirty'] ? ', lib/ has uncommitted changes' : ''
      "#{provider}/#{model} @ #{git['branch']} #{git['sha'][0, 8]} (lib #{lib_hash[0, 8]}#{dirty})"
    end
  end
end

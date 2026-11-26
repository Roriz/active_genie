# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Runs the selected cases through the eval's `call` block and caches one JSON record per case under
    # evals/<name>/runs/<system>-<code hash>/r<replicate>/<id>.json. Cached cases are never paid for
    # twice; errored cases are retried on the next run.
    class Runner
      USAGE_KEY = :active_genie_eval_usage
      # What the `call` block gets besides the input: which provider and model this run is for, and the row.
      Context = Struct.new(:provider, :model, :row, keyword_init: true)

      attr_reader :system, :items, :replicate

      def initialize(system:, items:, replicate: 1, concurrency: nil, io: $stdout)
        @system = system
        @items = items
        @replicate = replicate
        @concurrency = concurrency || Eval.config['concurrency'] || 1
        @io = io
      end

      def record_path(item)
        File.join(system.run_dir(replicate), "#{item.id}.json")
      end

      def pending
        items.reject do |item|
          record = item.cached_record(record_path(item))
          record && !record['error']
        end
      end

      # Rough cost of the pending cases, from the tokens earlier runs of this eval used.
      def estimate
        todo = pending
        per_case = tokens_per_case
        tokens = { 'input' => per_case['input'] * todo.size, 'output' => per_case['output'] * todo.size }
        price = (Eval.config['usd_per_million_tokens'] || {})[system.model]
        usd = price && (((tokens['input'] * price['input']) + (tokens['output'] * price['output'])) / 1_000_000.0)
        { 'cases' => todo.size, 'input_tokens' => tokens['input'], 'output_tokens' => tokens['output'], 'usd' => usd }
      end

      # `judge`: whether to call the (paid) judge too; the rake tasks pass it only with YES=1.
      def run!(judge: true)
        todo = pending
        configure!
        if todo.empty?
          @io.puts('Nothing to run: every selected case is cached.')
        else
          write_manifest(todo.size)
          run_pool(todo)
          @io.puts
        end
        judge! if judge
      end

      # Grades every cached case once with the judge online, so the free report never has to call it.
      def judge!
        Judge.online = true
        failures = items.filter_map do |item|
          record = item.cached_record(record_path(item))
          Graders.grade(system.definition, item.gold, record) if record
          nil
        rescue StandardError => e
          "#{item.key}: #{e.class}: #{e.message.lines.first&.strip}"
        end
        @io.puts("Grading with the judge failed on #{failures.size} case(s), e.g. #{failures.first}") if failures.any?
      ensure
        Judge.online = false
      end

      class << self
        # Whether the usage observer is already on ActiveGenie's log (it is added once per process).
        attr_accessor :observing
      end

      # Usage is counted per worker thread, from ActiveGenie's :llm_usage logs.
      def self.record_usage(log)
        usage = Thread.current.thread_variable_get(USAGE_KEY)
        return unless usage && log[:code] == :llm_usage

        usage['calls'] += 1
        usage['input_tokens'] += log[:input_tokens].to_i
        usage['output_tokens'] += log[:output_tokens].to_i
      end

      private

      # Points ActiveGenie at the run's provider and model (when the app's feature uses ActiveGenie) and
      # counts its token usage. The app's own log observers and output are kept.
      def configure!
        ActiveGenie.configure do |config|
          config.providers.default = system.provider if system.provider
          config.llm.model = system.model if system.model
          config.log.add_observer { |log| Runner.record_usage(log) } unless Runner.observing
        end
        Runner.observing = true
      end

      def run_pool(todo)
        queue = Queue.new
        todo.each { |item| queue << item }
        mutex = Mutex.new
        workers = Array.new([@concurrency, todo.size].min) do
          Thread.new do
            while (item = next_item(queue))
              record = run_one(item)
              mutex.synchronize { @io.print(record['error'] ? 'E' : '.') }
            end
          end
        end
        workers.each(&:join)
      end

      def next_item(queue)
        queue.pop(true)
      rescue ThreadError
        nil
      end

      def run_one(item)
        usage = { 'calls' => 0, 'input_tokens' => 0, 'output_tokens' => 0 }
        Thread.current.thread_variable_set(USAGE_KEY, usage)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        body = begin
          { 'output' => serialize(wrap { call(item) }) }
        rescue StandardError, ScriptError => e # NotImplementedError and LoadError are ScriptErrors
          { 'error' => "#{e.class}: #{e.message}"[0, 1000] }
        end
        latency = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        record = { 'id' => item.id, 'set' => item.set, 'replicate' => replicate, 'input_sha' => item.input_sha }
                 .merge(body, 'usage' => usage, 'latency_s' => latency.round(2), 'at' => Time.now.utc.iso8601)
        Store.write_json(record_path(item), record)
        record
      end

      def call(item)
        subject = system.definition.subject || raise(Error, "#{system.definition.name}: eval.rb has no `call` block")
        context = Context.new(provider: system.provider, model: system.model, row: item.case)
        subject.arity == 1 ? subject.call(item.case['input']) : subject.call(item.case['input'], context)
      end

      # Inside a Rails app, each case runs like a request: with the app's executor (autoloading,
      # connection pool and query cache handled per case).
      def wrap(&)
        return yield unless defined?(::Rails) && ::Rails.respond_to?(:application) && ::Rails.application

        ::Rails.application.executor.wrap(&)
      end

      # ActiveGenie::Result keeps data, reasoning and small metadata; anything else becomes JSON data.
      def serialize(result)
        if result.is_a?(ActiveGenie::Result)
          return { 'data' => json(result.data), 'reasoning' => result.reasoning,
                   'metadata' => scalars(result.metadata) }
        end

        { 'data' => json(result) }
      end

      def json(value)
        JSON.parse(JSON.generate(value))
      rescue JSON::GeneratorError, JSON::ParserError, TypeError
        value.to_s
      end

      def scalars(metadata)
        return {} unless metadata.is_a?(Hash)

        metadata.select { |_k, v| v.is_a?(Numeric) || v.is_a?(String) || v == true || v == false }
                .transform_keys(&:to_s).reject { |_k, v| v.is_a?(String) && v.size > 2000 }
      end

      def write_manifest(count)
        file = File.join(system.run_dir(replicate), 'manifest.json')
        fresh = { 'eval' => system.definition.name, 'provider' => system.provider, 'model' => system.model,
                  'code_hash' => system.code_hash, 'rounds' => [] }
        manifest = File.exist?(file) ? JSON.parse(File.read(file)) : fresh
        manifest['rounds'] << system.git.merge('at' => Time.now.utc.iso8601, 'cases' => count)
        Store.write_json(file, manifest)
      end

      # Average tokens per case from every cached record of this eval (runs and baselines).
      def tokens_per_case
        records = Dir.glob(system.definition.path('{runs,baselines}', '*', 'r*', '*.json'))
                     .reject { |f| File.basename(f) == 'manifest.json' }
                     .map { |f| JSON.parse(File.read(f)) }
                     .select { |r| r.dig('usage', 'calls').to_i.positive? }
        return Eval.config['default_tokens_per_case'] || { 'input' => 3000, 'output' => 1000 } if records.empty?

        %w[input output].to_h { |k| [k, records.sum { |r| r.dig('usage', "#{k}_tokens") } / records.size] }
      end
    end
  end
end

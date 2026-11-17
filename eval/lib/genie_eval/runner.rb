# frozen_string_literal: true

module GenieEval
  # Runs the selected cases against one system and caches one JSON record per case under
  # eval/runs/<system>-<lib hash>/r<replicate>/<cell>/<id>.json. Cached cases are never paid for
  # twice; errored cases are retried on the next run.
  class Runner
    USAGE_KEY = :genie_eval_usage

    attr_reader :system, :items, :replicate

    def initialize(system:, items:, replicate: 1, concurrency: nil, io: $stdout)
      @system = system
      @items = items
      @replicate = replicate
      @concurrency = concurrency || GenieEval.config.fetch('concurrency')
      @io = io
    end

    def record_path(item)
      File.join(system.run_dir(replicate), item.cell, "#{item.case['id']}.json")
    end

    def pending
      items.reject do |item|
        record = item.cached_record(record_path(item))
        record && !record['error']
      end
    end

    # Rough cost of the pending cases, from tokens seen in earlier runs of the same cell.
    def estimate
      todo = pending
      tokens = todo.each_with_object(Hash.new(0)) do |item, sum|
        Estimator.tokens_per_case(item.cell).each { |k, v| sum[k] += v }
      end
      price = GenieEval.config.fetch('usd_per_million_tokens')[system.model]
      usd = price && (((tokens['input'] * price['input']) + (tokens['output'] * price['output'])) / 1_000_000)
      { 'cases' => todo.size, 'input_tokens' => tokens['input'], 'output_tokens' => tokens['output'], 'usd' => usd }
    end

    def run!
      todo = pending
      self.class.configure!(system)
      if todo.empty?
        @io.puts('Nothing to run: every selected case is cached.')
      else
        write_manifest(todo.size)
        run_pool(todo)
        @io.puts
      end
      judge!
    end

    # Grades every cached case once with the judge online, so the free report never has to call it.
    # A judge failure leaves the field `unjudged` and is retried on the next run.
    def judge!
      Judge.online = true
      gold = Hash.new { |h, cell| h[cell] = Store.gold(cell) }
      failures = items.filter_map do |item|
        record = item.cached_record(record_path(item))
        next unless record

        Graders.grade(item.cell, gold[item.cell].fetch(item.case['id'])['gold'], record)
        nil
      rescue StandardError => e
        "#{item.key}: #{e.class}: #{e.message.lines.first&.strip}"
      end
      @io.puts("Judge failed on #{failures.size} case(s), e.g. #{failures.first}") if failures.any?
    ensure
      Judge.online = false
    end

    def self.configure!(system)
      require File.join(REPO, 'lib', 'active_genie')
      ActiveGenie.configure do |config|
        config.providers.default = system.provider
        config.llm.model = system.model
        config.log.output = ->(_log) {}
        config.log.clear_observers
        config.log.add_observer { |log| record_usage(log) }
      end
    end

    # Usage is collected per worker thread; fibers inside ActiveGenie share the thread variable.
    def self.record_usage(log)
      usage = Thread.current.thread_variable_get(USAGE_KEY)
      return unless usage && log[:code] == :llm_usage

      usage['calls'] += 1
      usage['input_tokens'] += log[:input_tokens].to_i
      usage['output_tokens'] += log[:output_tokens].to_i
    end

    private

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
        Executor.call(item.cell, item.case['input'])
      rescue StandardError => e
        { 'error' => "#{e.class}: #{e.message}"[0, 1000] }
      end
      latency = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      record = { 'id' => item.case['id'], 'cell' => item.cell, 'replicate' => replicate, 'input_sha' => item.input_sha }
               .merge(body, 'usage' => usage, 'latency_s' => latency.round(2), 'at' => Time.now.utc.iso8601)
      Store.write_json(record_path(item), record)
      record
    end

    def write_manifest(count)
      file = File.join(system.run_dir(replicate), 'manifest.json')
      fresh = { 'provider' => system.provider, 'model' => system.model, 'lib_hash' => system.lib_hash, 'rounds' => [] }
      manifest = File.exist?(file) ? JSON.parse(File.read(file)) : fresh
      manifest['rounds'] << system.git.merge('at' => Time.now.utc.iso8601, 'cases' => count)
      Store.write_json(file, manifest)
    end
  end

  # Average tokens per case, learned from every cached record (runs and baselines).
  module Estimator
    module_function

    def tokens_per_case(cell)
      @cache ||= {}
      @cache[cell] ||= begin
        records = Dir.glob(GenieEval.path('{runs,baselines}', '*', 'r*', cell, '*.json'))
                     .map { |f| JSON.parse(File.read(f)) }
                     .select { |r| r.dig('usage', 'calls').to_i.positive? }
        records.empty? ? default(cell) : average(records)
      end
    end

    def average(records)
      %w[input output].to_h { |k| [k, records.sum { |r| r.dig('usage', "#{k}_tokens") } / records.size] }
    end

    def default(cell)
      base = GenieEval.config.fetch('default_tokens_per_case')
      factor = cell.start_with?('comparator.') ? 2 : 1 # both orders
      base.transform_values { |v| v * factor }
    end
  end
end

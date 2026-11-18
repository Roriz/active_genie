# frozen_string_literal: true

module GenieEval
  # Promotes a complete run to the committed baseline of its provider/model, and (for the dev
  # model) assigns dev-pool roles: canary = the baseline passes in every replicate, hard = it fails.
  module Baseline
    module_function

    def save!(system, items, saved_by:, force: false)
      validate!(system, items, force:)
      FileUtils.rm_rf(system.baseline_dir)
      FileUtils.mkdir_p(system.baseline_dir)
      system.replicates.each do |r|
        FileUtils.cp_r(system.run_dir(r), File.join(system.baseline_dir, "r#{r}"))
      end
      Store.write_json(File.join(system.baseline_dir, 'BASE.json'), meta(system, items, saved_by))
      assign_roles!(system, items) if system.dev?
    end

    def validate!(system, items, force:)
      raise Error, "no run for #{system.name} at lib #{system.lib_hash[0, 8]}; run `rake eval:full` first" if system.replicates.empty?

      system.replicates.each do |r|
        results = Results.load(system.run_root, items, replicate: r)
        bad = results.missing + results.errors
        raise Error, "replicate r#{r} is incomplete (#{bad.size} missing or errored, e.g. #{bad.first.key})" if bad.any?
        next if force

        unjudged = results.rows.count { |row| row.grade.detail.fetch('fields', {}).value?('unjudged') }
        raise Error, "replicate r#{r} has #{unjudged} case(s) waiting for the judge; run with YES=1 (FORCE=1 overrides)" if unjudged.positive?
      end
      return if force || !system.git['lib_dirty']

      raise Error, 'lib/ has uncommitted changes; a baseline must match a commit (FORCE=1 overrides)'
    end

    def meta(system, items, saved_by)
      system.git.merge(
        'provider' => system.provider, 'model' => system.model, 'lib_hash' => system.lib_hash,
        'replicates' => system.replicates, 'cases' => items.size,
        'saved_by' => saved_by, 'saved_at' => Time.now.utc.iso8601
      )
    end

    def assign_roles!(system, items)
      runs = system.replicates.map { |r| Results.load(system.run_root, items, replicate: r).by_key }
      pools = Store.pools.map do |row|
        next row unless row['pool'] == 'dev'

        key = "#{row['cell']}/#{row['id']}"
        passes = runs.map { |run| run[key]&.pass? }
        next row if passes.include?(nil)

        row.merge('role' => passes.all? ? 'canary' : 'hard')
      end
      Store.write_pools(pools)
    end
  end
end

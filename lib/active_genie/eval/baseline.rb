# frozen_string_literal: true

module ActiveGenie
  module Eval
    # Promotes a complete run to the committed baseline of its eval, provider and model.
    module Baseline
      module_function

      def save!(system, items, saved_by:, force: false)
        validate!(system, items, force:)
        FileUtils.rm_rf(system.baseline_dir)
        FileUtils.mkdir_p(system.baseline_dir)
        system.replicates.each { |r| FileUtils.cp_r(system.run_dir(r), File.join(system.baseline_dir, "r#{r}")) }
        Store.write_json(File.join(system.baseline_dir, 'BASE.json'), meta(system, items, saved_by))
      end

      def validate!(system, items, force:)
        if system.replicates.empty?
          raise Error, "no run of #{system.definition.name} for this code; run `active_genie:eval:full` first"
        end

        system.replicates.each do |r|
          results = Results.load(system.definition, system.run_root, items, replicate: r)
          bad = results.missing + results.errors
          raise Error, "replicate r#{r} is incomplete (#{bad.size} missing or errored, e.g. #{bad.first.key})" if bad.any?
          next if force

          unjudged = results.rows.count { |row| row.grade.unjudged? }
          raise Error, "replicate r#{r} has #{unjudged} case(s) waiting for the judge; run the eval again to judge them (FORCE=1 overrides)" if unjudged.positive?
        end
        return if force || !system.git['dirty']

        raise Error, 'the watched files have uncommitted changes; a baseline must match a commit (FORCE=1 overrides)'
      end

      def meta(system, items, saved_by)
        system.git.merge(
          'eval' => system.definition.name, 'provider' => system.provider, 'model' => system.model,
          'code_hash' => system.code_hash, 'replicates' => system.replicates, 'cases' => items.size,
          'saved_by' => saved_by, 'saved_at' => Time.now.utc.iso8601
        )
      end
    end
  end
end

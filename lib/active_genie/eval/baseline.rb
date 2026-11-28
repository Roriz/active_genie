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
        name = system.definition.name
        raise NoRunToBaselineError, name if system.replicates.empty?

        system.replicates.each do |r|
          results = Results.load(system.definition, system.run_root, items, replicate: r)
          bad = results.missing + results.errors
          raise IncompleteRunError.new(name, replicate: r, count: bad.size, example: bad.first.key) if bad.any?
          next if force

          unjudged = results.rows.count { |row| row.grade.unjudged? }
          raise UnjudgedRunError.new(name, replicate: r, count: unjudged) if unjudged.positive?
        end
        return if force || !system.git['dirty']

        raise DirtyWorktreeError, name
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

# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/eval'

# The gem's own evals in evals/ are data like any app's: this runs the free check on them, so a broken
# dataset, gold or eval.rb fails CI. No model is called.
class GemEvalsTest < Minitest::Test
  Eval = ActiveGenie::Eval

  def setup
    Eval.reset!
    Eval.app_root = File.expand_path('../../..', __dir__)
  end

  def teardown
    Eval.app_root = nil
    Eval.reset!
  end

  def test_the_gem_evals_pass_the_check
    check = Eval::Check.new.run

    assert_predicate check, :ok?, check.report
  end

  def test_every_eval_has_cases_and_watches_the_library_not_the_engine
    expected = %w[comparator extractor extractor_with_litote lister_with_feud lister_with_juries
                  scorer_by_jury_bench]

    assert_equal expected, Eval.load!.keys.sort
    Eval.definitions.each_value do |definition|
      refute_empty Eval::Selection.call(definition, 'full'), "#{definition.name} has no runnable case"
      refute(definition.watched_files.any? { |f| f.start_with?('lib/active_genie/eval', 'lib/tasks') },
             "#{definition.name} must not watch the eval engine")
    end
    assert_equal %w[by_debate by_fight], Eval.fetch('comparator').variant_names
    assert_equal %w[data with_explanation], Eval.fetch('extractor').variant_names
  end
end

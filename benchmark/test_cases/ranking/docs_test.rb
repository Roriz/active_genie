# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Ranking
    class DocsTest < Minitest::Test
      def test_what_doc_needs_update
        docs = JSON.parse(File.read('benchmark/test_cases/assets/docs.json'))
        pr_description = <<~CRITERIA
          Identify which of two provided documentation titles and summaries is more likely to need updating based on a given Pull Request (PR) description. Only respond with the title of the document that directly requires updates once the PR is merged.

          # Steps

          1. **Analyze the PR Description**: Review the provided PR description to identify key changes being proposed.
          2. **Examine Document Summaries**: Read both documentation summaries and determine the scope and content covered in each.
          3. **Compare Against PR Changes**: Compare the identified changes from the PR with the content covered in each documentation summary.
          4. **Determine Necessity of Update**: Decide which, if any, of the documentations will need to be directly updated once the PR is merged based on relevance to the changes.

          # Notes

          - Consider all changes proposed in the PR description.
          - Focus on direct impacts that necessitate updates in documentation. Avoid speculation about indirect changes.

          PR description:#{' '}
          """
          PR introduces a new advanced filtering system for the search page with a feature flagging implementation.

          The changes include:
          - A new feature flag system (search_filters_enabled) to control the rollout of all new filter components
          - Granular feature flags for individual filter types (date_filter, category_filter, saved_preferences)
          - Backend configuration service enhancements to manage feature flag states across environments
          - A new date range filter component that respects feature flag settings
          - Category-based filtering with multi-select capabilities controlled by feature flags
          - Saved filter preferences feature with progressive enablement through feature flags
          - Monitoring and analytics to track feature flag impact on user engagement
          """
        CRITERIA
        result = ActiveGenie::Ranking.call(docs, pr_description)

        feature_flag = result.index { |r| r[:content].include? 'Feature Flagging & Rollout' }
        retrospective = result.index { |r| r[:content].include? 'Retrospective & Postmortem Templates' }

        assert_equal 15, result.size
        assert_operator feature_flag, :<=, 3, "Feature Flagging & Rollout should be on top3 but it was #{feature_flag}"
        assert_operator retrospective, :>=, 10, "Retrospective & Postmortem Templates should be greater than 10 but it was #{retrospective}"
      end
    end
  end
end

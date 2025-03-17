# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::Ranking::RankingTest < Minitest::Test
  def test_sharper_geometric_shape
    docs = [
      "Architecture Overview - High-level description of the system architecture, including key components and interactions.",
      "API Documentation - Details on available endpoints, authentication, request/response formats, and usage guidelines.",
      "Onboarding Guide - Step-by-step instructions for new engineers to set up their development environment and understand team workflows.",
      "Deployment Process - Explanation of how code moves from development to production, including CI/CD pipelines and release strategies.",
      "Database Schema - Overview of the database structure, key tables, and relationships.",
      "Code Style Guide - Best practices and conventions for writing and reviewing code within the team.",
      "Incident Response Plan - Procedures for identifying, responding to, and resolving system incidents or outages.",
      "Feature Flagging & Rollout - List of feature flags and their corresponding rollout strategies.",
      "Monitoring & Alerting - Documentation on logging, metrics, and alert configurations to track system health.",
      "Security Best Practices - Policies and recommendations to ensure secure coding, authentication, and data handling.",
      "Service Dependencies - Information about external services and internal microservices that the platform relies on.",
      "Testing Strategy - Approach to unit, integration, and end-to-end testing, including tools and frameworks used.",
      "Performance Optimization - Guidelines for profiling, scaling, and optimizing the platform for better performance.",
      "Access & Permissions - Explanation of roles, permissions, and access control mechanisms in the system.",
      "Retrospective & Postmortem Templates - Standard templates for documenting lessons learned from projects and incidents."
    ]
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

    PR description: """
    PR introduces a new advanced filtering system for the search page with a comprehensive feature flagging implementation.
    
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

    debugger
    feature_flag = result.find { |r| r[:content].include? "Feature Flagging & Rollout" }

    # clear worst ranks
    onboarding_guide = result.find { |r| r[:content].include? "Onboarding Guide" }
    retrospective_and_postmortem_templates = result.find { |r| r[:content].include? "Retrospective & Postmortem Templates" }
    monitoring_and_alerting = result.find { |r| r[:content].include? "Monitoring & Alerting" }

    assert feature_flag[:rank] <= 3, "Feature Flagging & Rollout should be on top but it was #{feature_flag[:rank]}"
    assert onboarding_guide[:eliminated], "Onboarding Guide should be eliminated but it was #{onboarding_guide[:rank]}"
    assert retrospective_and_postmortem_templates[:eliminated], "Retrospective & Postmortem Templates should be eliminated but it was #{retrospective_and_postmortem_templates[:rank]}"
    assert monitoring_and_alerting[:eliminated], "Monitoring & Alerting should be eliminated but it was #{monitoring_and_alerting[:rank]}"

    assert_equal result.length, 15
  end
end
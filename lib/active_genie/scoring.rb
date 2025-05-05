# frozen_string_literal: true

require_relative 'scoring/generalist'
require_relative 'scoring/recommended_reviewers'

module ActiveGenie
  # See the [Scoring README](lib/active_genie/scoring/README.md) for more information.
  module Scoring
    module_function

    def call(...)
      Generalist.call(...)
    end

    def generalist(...)
      Generalist.call(...)
    end

    def recommended_reviewers(...)
      RecommendedReviewers.call(...)
    end
  end
end

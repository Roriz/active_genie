require_relative 'scoring/basic'
require_relative 'scoring/recommended_reviewers'

module ActiveGenie
  # See the [Scoring README](lib/active_genie/scoring/README.md) for more information.
  module Scoring
    module_function

    def basic(...)
      Basic.call(...)
    end

    def recommended_reviewers(...)
      RecommendedReviewers.call(...)
    end
  end
end

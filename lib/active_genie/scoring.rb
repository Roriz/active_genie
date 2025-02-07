require_relative 'scoring/basic'
require_relative 'scoring/recommended_reviews'

module ActiveGenie
  # See the [Scoring README](lib/active_genie/scoring/README.md) for more information.
  module Scoring
    module_function

    def basic(...)
      Basic.call(...)
    end

    def recommended_reviews(...)
      RecommendedReviews.call(...)
    end
  end
end

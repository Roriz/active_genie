require_relative 'scoring/basic'
require_relative 'scoring/recommended_reviews'

module ActiveGenie
  # Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers
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

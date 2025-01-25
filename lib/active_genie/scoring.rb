require_relative 'scoring/basic'
require_relative 'scoring/recommended_reviews'

module ActiveGenie
  # Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers
  module Scoring
    module_function

    def basic(text, criteria, reviewers = [], options: {})
      Basic.call(text, criteria, reviewers, options:)
    end

    def recommended_reviews(text, criteria, options: {})
      RecommendedReviews.call(text, criteria, options:)
    end
  end
end

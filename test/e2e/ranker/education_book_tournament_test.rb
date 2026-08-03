# frozen_string_literal: true

require_relative '../test_helper'

class EducationBookTournamentTest < Minitest::Test
  def test_rank_programming_books
    books = [
      JSON.generate(title: "Advanced Algorithms", description: "Deep dive into NP-completeness and graph theory"),
      JSON.generate(title: "Beginner HTML", description: "Learn HTML tags and basic CSS"),
      JSON.generate(title: "Intermediate Python", description: "Build web apps with Flask and Django")
    ]

    result = ActiveGenie::Ranker.by_tournament(books, "best for a CS undergrad learning complex theory")

    # The result should be an ActiveGenie::Result
    assert_kind_of ActiveGenie::Result, result

    ranked_books = result.data

    # Ensure all players are returned
    assert_equal 3, ranked_books.length, "Should rank exactly 3 books"

    # Beginner HTML should be ranked last for a CS undergrad learning complex theory
    beginner_html = books[1]
    advanced_algorithms = books[0]
    
    # WHY: A CS undergrad focused on theory needs advanced algorithms, not basic HTML
    assert_equal beginner_html, ranked_books.last, "Expected Beginner HTML to be ranked last, got: #{ranked_books.last}"
    assert_equal advanced_algorithms, ranked_books.first, "Expected Advanced Algorithms to be ranked first, got: #{ranked_books.first}"
  end
end

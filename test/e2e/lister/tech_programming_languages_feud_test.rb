# frozen_string_literal: true

require_relative '../test_helper'

class TechProgrammingLanguagesFeudTest < Minitest::Test
  def test_programming_languages_feud
    theme = "Top programming languages in 2024"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    top_answer = result.data.first.to_s.downcase

    # WHY: Python and JavaScript are universally recognized as the most popular languages
    assert(
      top_answer.include?('python') || top_answer.include?('javascript') || top_answer.include?('java'),
      "Expected top answer to contain python, javascript, or java, but got: #{result.data.inspect}"
    )
  end
end

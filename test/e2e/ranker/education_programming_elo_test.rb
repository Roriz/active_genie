# frozen_string_literal: true

require_relative '../test_helper'

class EducationProgrammingEloTest < Minitest::Test
  def test_rank_programming_languages
    languages = [
      JSON.generate(language: "Python", paradigm: "General purpose"),
      JSON.generate(language: "Scratch", paradigm: "Visual block-based"),
      JSON.generate(language: "COBOL", paradigm: "Legacy business")
    ]

    result = ActiveGenie::Ranker.by_elo(languages, "teaching young kids how to code")

    assert_kind_of ActiveGenie::Result, result

    ranked = result.data
    assert_equal 3, ranked.length

    scratch = languages[1]
    cobol = languages[2]

    # WHY: Scratch is specifically designed for kids, COBOL is completely inappropriate.
    assert_equal scratch, ranked.first, "Expected Scratch to be ranked first, got: #{ranked.first}"
    assert_equal cobol, ranked.last, "Expected COBOL to be ranked last, got: #{ranked.last}"
  end
end

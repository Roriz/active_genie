# frozen_string_literal: true

require_relative '../test_helper'

class TechJobPostingExplanationTest < Minitest::Test
  def test_extract_language_and_framework
    text = "We are seeking a Backend Developer experienced in building RESTful APIs. Must be proficient with Python and the Django ecosystem."
    schema = {
      language: { type: 'string', description: 'Primary programming language' },
      framework: { type: 'string', description: 'Primary software framework' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: Basic extraction with reasoning should still pull obvious facts properly
    assert_match(/python/i, data[:language], "Expected language to be Python, got #{data[:language]}")
    assert_match(/django/i, data[:framework], "Expected framework to be Django, got #{data[:framework]}")
    refute_empty result.reasoning, "Expected non-empty reasoning"
  end
end

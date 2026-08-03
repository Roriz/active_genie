# frozen_string_literal: true

require_relative '../test_helper'

class HrMessySkillsDataTest < Minitest::Test
  def test_extract_skills_from_messy_text
    text = "SKilz: profiecent in Rubby on rails, Javascript (ES6), HTML/CSS and some exp w/ Pythen and AWS microservices. Worked with databses like postgreSql."
    schema = {
      skills: { type: 'array', items: { type: 'string' }, description: 'List of technical skills and technologies mentioned' }
    }

    result = ActiveGenie::Extractor.data(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    # Extractor.data returns string keys; normalize before symbol access.
    data = result.data.transform_keys(&:to_sym)
    # WHY: LLM should normalize and identify entities despite misspellings (Rubby, Pythen, databses)
    skills_text = data[:skills].map(&:to_s).join(' ').downcase
    assert_match(/ruby( on rails)?/, skills_text, "Expected skills to include Ruby, got #{data[:skills]}")
    assert_match(/python/, skills_text, "Expected skills to include Python despite typo, got #{data[:skills]}")
    assert_match(/postgresql/, skills_text, "Expected skills to include PostgreSQL, got #{data[:skills]}")
    assert_match(/aws/, skills_text, "Expected skills to include AWS, got #{data[:skills]}")
  end
end

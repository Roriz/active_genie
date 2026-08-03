# frozen_string_literal: true

require_relative '../test_helper'

class HrResumeDataTest < Minitest::Test
  def setup
    @resume_text = load_fixture('hr/resume_data.txt')
    @schema = {
      candidate_name: {
        type: 'string',
        description: 'Full name of the candidate'
      },
      years_experience: {
        type: 'integer',
        description: 'Total years of professional engineering experience'
      },
      primary_skills: {
        type: 'array',
        items: { type: 'string' },
        description: 'Top programming languages and key technology skills'
      }
    }
  end

  def test_extracts_hr_resume_data_directly
    result = ActiveGenie::Extractor.data(@resume_text, @schema)

    assert_kind_of ActiveGenie::Result, result
    refute_nil result.data
    name = result.data[:candidate_name] || result.data['candidate_name']
    experience = result.data[:years_experience] || result.data['years_experience']
    skills = result.data[:primary_skills] || result.data['primary_skills']

    assert_equal 'Alex Rivera', name
    assert_operator experience.to_i, :>=, 8
    assert_kind_of Array, skills
    refute_empty skills
  end
end

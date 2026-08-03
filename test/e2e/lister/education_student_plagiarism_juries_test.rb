# frozen_string_literal: true

require_relative '../test_helper'

class EducationStudentPlagiarismJuriesTest < Minitest::Test
  def test_student_plagiarism_juries
    text = "Reviewing a final year thesis that allegedly contains uncredited passages from published papers"
    criteria = "Evaluate academic integrity and originality"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Academic plagiarism cases are judged by professors, academics, or academic integrity boards
    has_academic = juries.any? { |j| j.include?('academic') || j.include?('professor') || j.include?('educator') || j.include?('faculty') }

    assert(
      has_academic,
      "Expected juries to include an academic or professor, but got: #{result.data.inspect}"
    )
  end
end

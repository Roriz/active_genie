# frozen_string_literal: true

require_relative '../test_helper'

class LegalSemiconductorPatentJuriesTest < Minitest::Test
  def test_semiconductor_patent_juries
    text = "Analyzing a new microchip architecture for potential infringement on existing US patents"
    criteria = "Evaluate intellectual property boundaries and technical overlap"
    result = ActiveGenie::Lister.with_juries(text, criteria)

    assert_kind_of ActiveGenie::Result, result
    juries = result.data.map { |a| a.to_s.downcase }

    # WHY: Patent infringement of a chip requires legal IP experts and hardware engineers
    has_expert = juries.any? { |j| j.include?('patent') || j.include?('attorney') || j.include?('semiconductor') || j.include?('engineer') || j.include?('ip') }

    assert(
      has_expert,
      "Expected juries to include patent/IP attorney or semiconductor engineer, but got: #{result.data.inspect}"
    )
  end
end

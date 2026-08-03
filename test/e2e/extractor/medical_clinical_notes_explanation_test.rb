# frozen_string_literal: true

require_relative '../test_helper'

class MedicalClinicalNotesExplanationTest < Minitest::Test
  def test_extract_diagnosis_and_severity
    text = "Patient presents with acute pharyngitis. Symptoms are moderate, primarily consisting of a sore throat and low-grade fever. Prescribed antibiotics."
    schema = {
      diagnosis: { type: 'string', description: 'Medical diagnosis' },
      severity: { type: 'string', description: 'Severity of the condition (e.g. mild, moderate, severe)' }
    }

    result = ActiveGenie::Extractor.with_explanation(text, schema)
    
    assert_kind_of ActiveGenie::Result, result
    
    data = result.data
    # WHY: LLM should extract explicit clinical info while providing chain-of-thought
    assert_match(/pharyngitis/i, data[:diagnosis], "Expected diagnosis to include pharyngitis, got #{data[:diagnosis]}")
    assert_match(/moderate/i, data[:severity], "Expected severity to be moderate, got #{data[:severity]}")
    refute_nil result.reasoning, "Expected reasoning to be present"
  end
end

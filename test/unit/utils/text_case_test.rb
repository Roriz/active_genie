# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/utils/text_case'

module ActiveGenie
  class TextCaseTest < Minitest::Test
    # Providers validate JSON schema property keys. Anthropic rejects anything
    # outside this pattern with a 400, so every output must satisfy it.
    SCHEMA_KEY_PATTERN = /\A[a-zA-Z0-9_.-]{1,64}\z/

    def test_underscores_camel_case
      assert_equal 'senior_software_engineer', TextCase.underscore('SeniorSoftwareEngineer')
    end

    def test_underscores_spaces
      assert_equal 'senior_software_engineer', TextCase.underscore('Senior Software Engineer')
    end

    def test_underscores_lowercase_words_with_spaces
      assert_equal 'senior_software_engineer', TextCase.underscore('senior software engineer')
    end

    def test_converts_hyphens
      assert_equal 'front_end_developer', TextCase.underscore('Front-End Developer')
    end

    def test_strips_punctuation
      assert_equal 'data_analytics_lead', TextCase.underscore('Data & Analytics Lead')
      assert_equal 'nurse_icu', TextCase.underscore('Nurse (ICU)')
      assert_equal 'chef_s_advocate', TextCase.underscore("Chef's Advocate")
    end

    def test_collapses_and_trims_separators
      assert_equal 'spaced_out', TextCase.underscore('  spaced  out  ')
    end

    def test_replaces_namespace_separator
      assert_equal 'foo_bar', TextCase.underscore('Foo::Bar')
    end

    def test_truncates_to_sixty_four_characters
      assert_equal 64, TextCase.underscore('A' * 80).length
    end

    def test_respects_a_smaller_max_length
      assert_equal 20, TextCase.underscore('A' * 80, max_length: 20).length
    end

    # Callers append suffixes like "_reasoning" to build schema property keys.
    # The combined key still has to satisfy the provider limit.
    def test_leaves_room_for_a_caller_suffix
      long_jury = 'Senior Cybersecurity Compliance and Risk Assessment Specialist for Banks'
      key = TextCase.underscore(long_jury, max_length: 64 - '_reasoning'.length)

      ['_reasoning', '_score'].each do |suffix|
        assert_match SCHEMA_KEY_PATTERN, "#{key}#{suffix}"
      end
    end

    def test_does_not_end_on_a_separator_after_truncation
      refute TextCase.underscore('Data and Analytics', max_length: 5).end_with?('_')
    end

    def test_falls_back_when_nothing_usable_remains
      assert_equal 'unnamed', TextCase.underscore('&&&')
      assert_equal 'unnamed', TextCase.underscore('')
      assert_equal 'unnamed', TextCase.underscore(nil)
    end

    def test_every_output_is_a_valid_schema_key
      [
        'Senior Software Engineer', 'senior software engineer', 'Data & Analytics Lead',
        'Nurse (ICU)', "Chef's Advocate", 'Front-End Developer', 'Foo::Bar',
        '  spaced  out  ', '&&&', '', nil, 'A' * 80, "Dr. Jane's Panel",
        'Coast Guard Officer', 'Público / Saúde'
      ].each do |input|
        key = TextCase.underscore(input)

        assert_match SCHEMA_KEY_PATTERN, key, "#{input.inspect} produced an invalid schema key"
      end
    end
  end
end

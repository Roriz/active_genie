# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  class ExtractorTest < Minitest::Test
    empty_tests = JSON.parse(File.read(File.join(__dir__, 'with_explanation/empty.json')), symbolize_names: true)
    empty_tests.each_with_index do |test, index|
      define_method("test_empty_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_explanation(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    marketplace_tests = JSON.parse(File.read(File.join(__dir__, 'with_explanation/marketplace.json')), symbolize_names: true)
    marketplace_tests.each_with_index do |test, index|
      define_method("test_marketplace_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_explanation(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    others_tests = JSON.parse(File.read(File.join(__dir__, 'with_explanation/others.json')), symbolize_names: true)
    others_tests.each_with_index do |test, index|
      define_method("test_others_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_explanation(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    social_media_tests = JSON.parse(File.read(File.join(__dir__, 'with_explanation/social_media.json')),
                                    symbolize_names: true)
    social_media_tests.each_with_index do |test, index|
      define_method("test_social_media_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_explanation(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    litote_affirmative_tests = JSON.parse(File.read(File.join(__dir__, 'with_litote/affirmative.json')),
                                          symbolize_names: true)
    litote_affirmative_tests.each_with_index do |test, index|
      define_method("test_litote_affirmative_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_litote(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    litote_litotes_tests = JSON.parse(File.read(File.join(__dir__, 'with_litote/litotes.json')), symbolize_names: true)
    litote_litotes_tests.each_with_index do |test, index|
      define_method("test_litote_litotes_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::Extractor.with_litote(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    private

    def module_asserts(result, expected)
      expected.each do |key, value|
        result_value = result[key.to_sym]

        assert result_value, "Missing key: #{key}, result: #{result.to_s[0..100]}"

        if value.is_a?(Array)
          assert_predicate result_value.intersection(value).size, :positive?, "Expected #{value}, but was #{result_value}"
        elsif value.is_a?(String)
          assert result_value.include?(value) || value.include?(result_value), "Expected #{value}, but was #{result_value}"
        else
          assert_equal result_value, value, "Expected #{value}, but was #{result_value}"
        end
      end

      assert_equal 0, result.keys.size, "Expected no keys, but was #{result.keys.size}" if expected.keys.empty?
    end
  end
end

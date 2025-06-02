# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  class DataExtractorTest < Minitest::Test
    empty_tests = JSON.parse(File.read(File.join(__dir__, 'generalist/empty.json')), symbolize_names: true)
    empty_tests.each_with_index do |test, index|
      define_method("test_empty_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::Generalist.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    marketplace_tests = JSON.parse(File.read(File.join(__dir__, 'generalist/marketplace.json')), symbolize_names: true)
    marketplace_tests.each_with_index do |test, index|
      define_method("test_marketplace_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::Generalist.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    others_tests = JSON.parse(File.read(File.join(__dir__, 'generalist/others.json')), symbolize_names: true)
    others_tests.each_with_index do |test, index|
      define_method("test_others_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::Generalist.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    social_media_tests = JSON.parse(File.read(File.join(__dir__, 'generalist/social_media.json')), symbolize_names: true)
    social_media_tests.each_with_index do |test, index|
      define_method("test_social_media_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::Generalist.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    from_informal_affirmative_tests = JSON.parse(File.read(File.join(__dir__, 'from_informal/affirmative.json')), symbolize_names: true)
    from_informal_affirmative_tests.each_with_index do |test, index|
      define_method("test_from_informal_affirmative_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::FromInformal.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    from_informal_litotes_tests = JSON.parse(File.read(File.join(__dir__, 'from_informal/litotes.json')), symbolize_names: true)
    from_informal_litotes_tests.each_with_index do |test, index|
      define_method("test_from_informal_litotes_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::FromInformal.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    from_informal_negative_tests = JSON.parse(File.read(File.join(__dir__, 'from_informal/negative.json')), symbolize_names: true)
    from_informal_negative_tests.each_with_index do |test, index|
      define_method("test_from_informal_negative_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
        result = ActiveGenie::DataExtractor::FromInformal.call(*test[:input])
        module_asserts(result, test[:expected])
      end
    end

    private

    def module_asserts(result, expected)
      expected.each do |key, value|
        result_value = result[key.to_sym]

        assert result_value, "Missing key: #{key}, result: #{result.to_s[0..100]}"

        if value.is_a?(Array)
          assert result_value.intersection(value).size > 0, "Expected #{value}, but was #{result_value}"
        elsif value.is_a?(String)
          assert result_value.include?(value) || value.include?(result_value), "Expected #{value}, but was #{result_value}"
        else
          assert_equal result_value, value, "Expected #{value}, but was #{result_value}"
        end
      end

      assert_equal result.keys.size, 0, "Expected no keys, but was #{result.keys.size}" if expected.keys.empty?
    end
  end
end

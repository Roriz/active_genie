# frozen_string_literal: true

require_relative 'test_helper'

# The modules read their prompt and function files at runtime. Not every one is loaded by another
# unit test, so a blank prompt or broken JSON would otherwise only show up on a real call.
class PromptFilesTest < Minitest::Test
  LIB = File.expand_path('../../lib/active_genie', __dir__)
  MOJIBAKE = /Ã.|â€|ï»¿|�/

  def test_every_prompt_is_non_empty_utf8_text
    prompts = Dir.glob(File.join(LIB, '**', '*.prompt.md'))

    refute_empty prompts

    prompts.each do |file|
      text = File.read(file, encoding: 'UTF-8')

      assert_predicate text, :valid_encoding?, "#{file}: not valid UTF-8"
      refute_empty text.strip, "#{file}: empty prompt"
      refute_match MOJIBAKE, text, "#{file}: mojibake (broken encoding)"
    end
  end

  def test_every_function_schema_is_valid_json
    schemas = Dir.glob(File.join(LIB, '**', '*.json'))

    refute_empty schemas

    schemas.each do |file|
      assert_kind_of Hash, JSON.parse(File.read(file)), "#{file}: expected a JSON object"
    rescue JSON::ParserError => e
      flunk "#{file}: invalid JSON (#{e.message.lines.first.strip})"
    end
  end
end

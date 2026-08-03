# frozen_string_literal: true

require_relative '../test_helper'

class TechSocialMediaFeudTest < Minitest::Test
  def test_social_media_feud
    theme = "Most popular social media platforms"
    result = ActiveGenie::Lister.with_feud(theme)

    assert_kind_of ActiveGenie::Result, result
    answers = result.data.map { |a| a.to_s.downcase }

    # WHY: The top platforms are strictly known (Facebook, Instagram, TikTok, YouTube)
    found_count = 0
    found_count += 1 if answers.any? { |a| a.include?('facebook') }
    found_count += 1 if answers.any? { |a| a.include?('instagram') }
    found_count += 1 if answers.any? { |a| a.include?('tiktok') }
    found_count += 1 if answers.any? { |a| a.include?('youtube') || a.include?('x') || a.include?('twitter') }

    assert(
      found_count >= 2,
      "Expected at least 2 major platforms (facebook, instagram, tiktok, youtube), but got: #{result.data.inspect}"
    )
  end
end

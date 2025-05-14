# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveGenie
  module DataExtractor
    class YoutubeEventsTest < Minitest::Test

      def test_youtube_extract
        text = <<~STRING
        {\"publishedAt\":\"2025-04-25T14:59:40Z\",\"channelId\":\"UCC3ljLfioI4qN2_zmG_kseQ\",\"title\":\"Irina Nazarova (CEO @ Evil Martians) - Startup on Rails - Tropical on Rails 2025\",\"description\":\"Irina Nazarova took the virtual stage at Tropical on Rails 2025 with a clear mission: to support startups by building the missing tools and sharing her team’s real-world experience in successful iteration and scaling. In this talk, Irina shares practical insights, lessons learned, and field-tested strategies for technical teams aiming for sustainable growth.\\n\\n🙏 Huge thanks to our Platinum sponsors — Shopify and Linkana — for making this event possible. And to our Gold sponsors: SmartFit, Braze, JetRockets, and AppSignal. Your support helps grow the Rails ecosystem and empowers the global tech community!\\n\\n🔗 Follow Irina:\\n\\nTwitter: https://twitter.com/inazarova\\nLinkedIn: https://www.linkedin.com/in/irinanazarova/\\nGitHub: https://github.com/inazarova\\n\\n🌴 Follow Tropical on Rails:\\n\\nOfficial site: https://tropicalonrails.com\\nTwitter: https://twitter.com/tropicalonrails\\nLinkedIn: https://www.linkedin.com/company/tropicalonrails\\nMastodon: https://ruby.social/@tropicalonrails\\nBluesky: https://bsky.app/profile/tropicalonrails.bsky.social\\n\\n🙌 A heartfelt thank you to everyone who joined us in person and to the entire Rails community that makes this gathering so special. If you missed out on tickets this year, stay tuned — announcements for the 2026 edition are coming soon, and you won’t want to miss it!\",\"thumbnails\":{\"default\":{\"url\":\"https://i.ytimg.com/vi/_eLfPFxztjs/default.jpg\",\"width\":120,\"height\":90},\"medium\":{\"url\":\"https://i.ytimg.com/vi/_eLfPFxztjs/mqdefault.jpg\",\"width\":320,\"height\":180},\"high\":{\"url\":\"https://i.ytimg.com/vi/_eLfPFxztjs/hqdefault.jpg\",\"width\":480,\"height\":360},\"standard\":{\"url\":\"https://i.ytimg.com/vi/_eLfPFxztjs/sddefault.jpg\",\"width\":640,\"height\":480},\"maxres\":{\"url\":\"https://i.ytimg.com/vi/_eLfPFxztjs/maxresdefault.jpg\",\"width\":1280,\"height\":720}},\"channelTitle\":\"Tropical on Rails\",\"categoryId\":\"28\",\"liveBroadcastContent\":\"none\",\"defaultLanguage\":\"en-US\",\"localized\":{\"title\":\"Irina Nazarova (CEO @ Evil Martians) - Startup on Rails - Tropical on Rails 2025\",\"description\":\"Irina Nazarova took the virtual stage at Tropical on Rails 2025 with a clear mission: to support startups by building the missing tools and sharing her team’s real-world experience in successful iteration and scaling. In this talk, Irina shares practical insights, lessons learned, and field-tested strategies for technical teams aiming for sustainable growth.\\n\\n🙏 Huge thanks to our Platinum sponsors — Shopify and Linkana — for making this event possible. And to our Gold sponsors: SmartFit, Braze, JetRockets, and AppSignal. Your support helps grow the Rails ecosystem and empowers the global tech community!\\n\\n🔗 Follow Irina:\\n\\nTwitter: https://twitter.com/inazarova\\nLinkedIn: https://www.linkedin.com/in/irinanazarova/\\nGitHub: https://github.com/inazarova\\n\\n🌴 Follow Tropical on Rails:\\n\\nOfficial site: https://tropicalonrails.com\\nTwitter: https://twitter.com/tropicalonrails\\nLinkedIn: https://www.linkedin.com/company/tropicalonrails\\nMastodon: https://ruby.social/@tropicalonrails\\nBluesky: https://bsky.app/profile/tropicalonrails.bsky.social\\n\\n🙌 A heartfelt thank you to everyone who joined us in person and to the entire Rails community that makes this gathering so special. If you missed out on tickets this year, stay tuned — announcements for the 2026 edition are coming soon, and you won’t want to miss it!\"},\"defaultAudioLanguage\":\"en-US\"}
        STRING

        schema = {
          title: {
            type: "string",
            description: "cleaned up name of the talk title. Only the title of the talk itself. No event name, speaker names, speaker handles, etc",
          },
          raw_title: {
            type: "string",
            description: "original talk title, as in the title of the recording on youtube. This might usually also include the speaker, event name, speaker handle and more.",
          },
          speakers: {
            type: "array",
            description: "array of strings of the speaker names",
            items: {
              type: "string"
            }
          },
          event_name: {
            type: "string",
            description: "name of the event where the talk was held",
          },
          happened_at: {
            type: "string",
            description: "ISO-8601 as string formatted date of when the talk happened or 'unknown' if the date is not clear or incomplete.",
          },
          published_at: {
            type: "string",
            description: "ISO-8601 as string formatted datetime of when the talk recording was published, this is usually the YouTube uploaded at date",
          },
          announced_at: {
            type: "string",
            description: "ISO-8601 as string formatted datetime of when the talk was announced to the public. usually before the actual `held_at` of the talk. Do not make any guess. If announcement date is not clear, leave it empty.",
          },
          language: {
            type: "string",
            description: "",
            enum: ["english", "spanish", "portguese", "japanese"],
          },
          slides_url: {
            type: "string",
            description: "An optional link to the slides of the talk",
          }
        }

        result = ActiveGenie::DataExtractor.call(
          text,
          schema,
          config: {
            llm: {
              temperature: 0
            }
          }
        )

        assert_equal result['title'], "Startup on Rails"
        assert_equal result['raw_title'], "Irina Nazarova (CEO @ Evil Martians) - Startup on Rails - Tropical on Rails 2025"
        assert_equal result['speakers'], ["Irina Nazarova"], result['speakers_explanation']
        assert_equal result['event_name'].include?("Tropical on Rails"), true
        assert_equal result['happened_at'], nil, result['happened_at_explanation']
        assert_equal result['published_at'], "2025-04-25T14:59:40Z", result['published_at_explanation']
        assert_equal result['announced_at'], nil, result['announced_at_explanation']
        assert_equal result['language'], "english", result['language_explanation']
        assert_equal result['slides_url'], nil, result['slides_url_explanation']
      end
    end
  end
end

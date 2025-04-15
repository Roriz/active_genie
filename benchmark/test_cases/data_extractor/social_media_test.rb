# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::DataExtractor::SocialTest < Minitest::Test
  SOCIAL = [
    { input: ["@alice posted: Just finished reading 'Atomic Habits'! Highly recommend it.", { user: { type: 'string' }, action: { type: 'string' }, }], expected: { user: 'alice', action: 'posted', content: "Just finished reading 'Atomic Habits'! Highly recommend it." } },
    { input: ["bob commented: Congrats on your new job, @alice!", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, }], expected: { user: 'bob', action: 'commented', target: 'alice', content: 'Congrats on your new job, @alice!' } },
    { input: ["@carol liked @dave's photo.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'carol', action: 'liked', target: 'dave', object: 'photo' } },
    { input: ["@eve retweeted @frank: Can't wait for the concert tonight!", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, }], expected: { user: 'eve', action: 'retweeted', target: 'frank', content: "Can't wait for the concert tonight!" } },
    { input: ["@grace replied to @heidi: Me too! See you there.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, }], expected: { user: 'grace', action: 'replied', target: 'heidi', content: 'Me too! See you there.' } },
    { input: ["@ivan shared @judy's post: Amazing sunset at the beach.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, }], expected: { user: 'ivan', action: 'shared', target: 'judy', content: 'Amazing sunset at the beach.' } },
    { input: ["@kate mentioned @leo in a comment: Happy birthday!", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, }], expected: { user: 'kate', action: 'mentioned', target: 'leo', content: 'Happy birthday!' } },
    { input: ["@mia followed @nick.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' } }], expected: { user: 'mia', action: 'followed', target: 'nick' } },
    { input: ["@oliver updated his status: Feeling grateful today.", { user: { type: 'string' }, action: { type: 'string' }, }], expected: { user: 'oliver', action: 'updated', content: 'Feeling grateful today.' } },
    { input: ["@paul uploaded a new video: 'My Travel Vlog'", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' }, }], expected: { user: 'paul', action: 'uploaded', object: 'video', content: 'My Travel Vlog' } },
    { input: ["@quinn checked in at Central Park.", { user: { type: 'string' }, action: { type: 'string' }, location: { type: 'string' } }], expected: { user: 'quinn', action: 'checked in', location: 'Central Park' } },
    { input: ["@rachel tagged @sam in a photo.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'rachel', action: 'tagged', target: 'sam', object: 'photo' } },
    { input: ["@tom sent @ursula a friend request.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'tom', action: 'sent', target: 'ursula', object: 'friend request' } },
    { input: ["@victor accepted @wendy's friend request.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'victor', action: 'accepted', target: 'wendy', object: 'friend request' } },
    { input: ["@xander created an event: 'Board Game Night' on Friday.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' }, date: { type: 'string' } }], expected: { user: 'xander', action: 'created', object: 'event', date: 'Friday' } },
    { input: ["@yara invited @zane to 'Board Game Night'.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, event: { type: 'string' } }], expected: { user: 'yara', action: 'invited', target: 'zane', event: 'Board Game Night' } },
    { input: ["@alice pinned a post: 'Weekly Motivation'", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' }, }], expected: { user: 'alice', action: 'pinned', object: 'post', content: 'Weekly Motivation' } },
    { input: ["@bob reported @carol's comment as spam.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'bob', action: 'reported', target: 'carol', object: 'comment' } },
    { input: ["@dave blocked @eve.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' } }], expected: { user: 'dave', action: 'blocked', target: 'eve' } },
    { input: ["@frank left a review: 5 stars for @grace's bakery!", { user: { type: 'string' }, action: { type: 'string' }, rating: { type: 'number' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'frank', action: 'left', rating: 5, target: 'grace', object: 'bakery' } },
    { input: ["@heidi updated her profile picture.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'heidi', action: 'updated', object: 'profile picture' } },
    { input: ["@ivan changed cover photo.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'ivan', action: 'changed', object: 'cover photo' } },
    { input: ["@judy joined the group 'Ruby Developers'.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'judy', action: 'joined', object: 'Ruby Developers' } },
    { input: ["@kate left the group 'Ruby Developers'.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'kate', action: 'left', object: 'Ruby Developers' } },
    { input: ["@leo reacted to @mia's post with a heart.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' }, reaction: { type: 'string' } }], expected: { user: 'leo', action: 'reacted', target: 'mia', object: 'post', reaction: 'heart' } },
    { input: ["@nick saved @oliver's recipe post.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'nick', action: 'saved', target: 'oliver', object: 'recipe post' } },
    { input: ["@paul unsubscribed from @quinn's channel.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'paul', action: 'unsubscribed', target: 'quinn', object: 'channel' } },
    { input: ["@rachel muted @sam's stories.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'rachel', action: 'muted', target: 'sam', object: 'stories' } },
    { input: ["@tom reported @ursula's video.", { user: { type: 'string' }, action: { type: 'string' }, target: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'tom', action: 'reported', target: 'ursula', object: 'video' } },
    { input: ["@victor shared a memory from 2 years ago.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' }, time: { type: 'string' } }], expected: { user: 'victor', action: 'shared', object: 'memory', time: '2 years ago' } },
    { input: ["@wendy started a live video.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'wendy', action: 'started', object: 'live video' } },
    { input: ["@xander went live: 'Coding Q&A Session'", { user: { type: 'string' }, action: { type: 'string' }, }], expected: { user: 'xander', action: 'went live', content: 'Coding Q&A Session' } },
    { input: ["@yara uploaded a story: 'Morning coffee vibes'", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' }, }], expected: { user: 'yara', action: 'uploaded', object: 'story', content: 'Morning coffee vibes' } },
    { input: ["@zane deleted a comment on his post.", { user: { type: 'string' }, action: { type: 'string' }, object: { type: 'string' } }], expected: { user: 'zane', action: 'deleted', object: 'comment' } },
  ]

  SOCIAL.each_with_index do |test, index|
    define_method("test_data_extractor_social_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}") do
      result = ActiveGenie::DataExtractor::Basic.call(*test[:input])

      test[:expected].each do |key, value|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        assert_equal value, result[key.to_s], "Expected #{value}, but was #{result[key.to_s]}"
      end
    end
  end
end
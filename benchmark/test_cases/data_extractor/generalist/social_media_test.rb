# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveGenie
  module DataExtractor
    class SocialTest < Minitest::Test
      FEATURES = %w[
        post comment like retweet reply share follow unfollow status
        block unblock invite decline review react subscribe unsubscribe
        muted report live
      ].freeze
      SOCIAL = [
        {
          input: ["@alice posted: Just finished reading 'Atomic Habits'! Highly recommend it.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'post' }
        },
        {
          input: ['bob commented: Congrats on your new job, @alice!',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'comment' }
        },
        {
          input: ["@carol liked @dave's photo.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'like' }
        },
        {
          input: ["@eve retweeted @frank: Can't wait for the concert tonight!",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'retweet' }
        },
        {
          input: ['@grace replied to @heidi: Me too! See you there.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'reply' }
        },
        {
          input: ["@ivan shared @judy's post: Amazing sunset at the beach.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'share' }
        },
        {
          input: ['@kate mentioned @leo in a comment: Happy birthday!',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'comment' }
        },
        {
          input: ['@mia followed @nick.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'follow' }
        },
        {
          input: ['@oliver updated his status: Feeling grateful today.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'status' }
        },
        {
          input: ["@paul uploaded a new video: 'My Travel Vlog'",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'post' }
        },
        {
          input: ['@rachel tagged @sam in a photo.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'post' }
        },
        {
          input: ['@xena blocked @yann.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'block' }
        },
        {
          input: ['@zack unblocked @alice.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'unblock' }
        },
        {
          input: ["@bob invited @carol to an event: 'Tech Meetup'",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'invite' }
        },
        {
          input: ['@eve declined the event invitation.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'decline' }
        },
        {
          input: ["@frank left a review: 5 stars for @grace's bakery!",
                  { feature: { type: 'string', enum: FEATURES },
                    rating: { type: 'number' } }], expected: { feature: 'review', rating: 5 }
        },
        {
          input: ["@leo reacted to @mia's post with a heart.",
                  { feature: { type: 'string', enum: FEATURES },
                    reaction: { type: 'string' } }], expected: { feature: 'react', reaction: 'heart' }
        },
        {
          input: ["@paul unsubscribed from @quinn's channel.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'unsubscribe' }
        },
        {
          input: ["@rachel muted @sam's stories.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'muted' }
        },
        {
          input: ["@tom reported @ursula's video.",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'report' }
        },
        {
          input: ['@victor shared a memory from 2 years ago.',
                  { feature: { type: 'string', enum: FEATURES },
                    time: { type: 'string' } }], expected: { feature: 'share', time: '2 years ago' }
        },
        {
          input: ['@wendy started a live video.',
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'live' }
        },
        {
          input: ["@xander went live: 'Coding Q&A Session'",
                  { feature: { type: 'string', enum: FEATURES } }], expected: { feature: 'live' }
        }
      ].freeze

      SOCIAL.each_with_index do |test, _index|
        define_method("test_data_extractor_social_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}") do
          result = ActiveGenie::DataExtractor.call(*test[:input])

          test[:expected].each do |key, value|
            assert result.key?(key), "Missing key: #{key}, result: #{result[0..100]}"
            assert_equal value, result[key], "Expected (#{key}) #{value}, but was #{result[key]}"
          end
        end
      end
    end
  end
end

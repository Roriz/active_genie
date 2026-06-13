# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Ranker
    module Entities
      class PlayerTest < Minitest::Test
        def test_initialization_with_string_keys
          params = { "name" => "Alice", "content" => "Alice is a writer", "score" => 80 }
          player = Player.new(params)

          assert_equal "Alice", player.name
          assert_equal "Alice is a writer", player.content
          assert_equal 80, player.score
        end

        def test_initialization_with_symbol_keys
          params = { name: "Bob", content: "Bob is a designer", score: 90 }
          player = Player.new(params)

          assert_equal "Bob", player.name
          assert_equal "Bob is a designer", player.content
          assert_equal 90, player.score
        end

        def test_no_circular_reference_in_serialization
          # String keys hash, where content is not specified but name is.
          # Previously, this triggered `@params[:content] ||= @params`, making the hash circular.
          params = { "name" => "Charlie", "details" => "A developer" }
          player = Player.new(params)

          # Verify that we can call to_h and serialize to JSON without JSON::NestingError
          hash = player.to_h
          assert_equal "Charlie", hash[:name]
          assert_equal params.transform_keys(&:to_sym), hash[:content]

          # This would raise JSON::NestingError previously
          assert_silent do
            JSON.generate(hash)
          end
        end

        def test_fallback_name_when_content_is_hash
          # Verify that when name is missing and content is a Hash, name doesn't crash on content[0..10]
          params = { "details" => "Something important" }
          player = Player.new(params)

          assert_match(/^\{:?details/, player.name)
        end

        def test_fallback_name_when_content_is_string
          params = { "content" => "Hello World!" }
          player = Player.new(params)

          assert_equal "Hello World", player.name
        end
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Eval
    # One eval: the code it calls, how answers are graded and which files it depends on.
    #
    #   ActiveGenie::Eval.define 'ticket_router' do
    #     call { |input| TicketRouter.new.route(input['text']) }
    #     grader :fields
    #     watch 'app/services/ticket_router.rb', 'app/prompts/ticket_router/**/*'
    #   end
    class Definition
      GRADERS = %w[fields band list rubric].freeze
      # config/initializers holds ActiveGenie's own settings (temperature, max_tokens, ...).
      DEFAULT_WATCH = ['app/**/*', 'lib/**/*', 'config/**/*.yml', 'config/initializers/**/*.rb', 'Gemfile.lock'].freeze

      # The block form of `ActiveGenie::Eval.define`.
      class Builder
        def initialize(definition)
          @definition = definition
        end

        # The code under test. It gets the row's `input` (and a context with the provider and model the
        # run uses) and returns whatever your feature returns: a Hash, a String, a number, a list or an
        # ActiveGenie::Result.
        def call(&block)
          @definition.subject = block
        end

        # :fields, :band, :list or :rubric (see evals/README.md), or a block
        # `{ |output, gold, row| ... }` returning true/false, or a Hash with "pass" and any details.
        def grader(name = nil, &block)
          @definition.grader = block || name.to_s
        end

        # Globs, from the app root, of the files the feature depends on. A change to any of them starts a
        # fresh run; outputs are cached per case until then.
        def watch(*globs)
          @definition.watch = globs.flatten.map(&:to_s)
        end
      end

      attr_reader :name, :dir
      attr_accessor :subject, :grader
      attr_writer :watch

      def initialize(name:, dir:)
        @name = name
        @dir = dir
        @grader = 'fields'
      end

      def watch
        @watch || DEFAULT_WATCH
      end

      def custom_grader?
        grader.respond_to?(:call)
      end

      def path(*parts)
        File.join(dir, *parts)
      end

      # The watched files plus this eval's eval.rb, sorted, relative to the app root.
      def watched_files
        root = Eval.app_root
        files = watch.flat_map { |glob| Dir.glob(File.join(root, glob)) } + [path('eval.rb')]
        files.select { |f| File.file?(f) }.map { |f| f.delete_prefix("#{root}/") }.uniq.sort
      end
    end
  end
end

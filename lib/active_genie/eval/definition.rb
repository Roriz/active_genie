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
    #
    # An eval can run several variants on the same cases instead of one `call`, to compare them head to
    # head (two prompts, two models, two methods):
    #
    #     variant(:v1) { |input| TicketRouter.new(prompt: :v1).route(input['text']) }
    #     variant(:v2) { |input| TicketRouter.new(prompt: :v2).route(input['text']) }
    class Definition
      GRADERS = %w[fields band list rubric winner].freeze
      NAME = /\A[a-z][a-z0-9_]*\z/
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

        # One of several subjects run on the same cases; the report compares them pair by pair.
        def variant(name, &block)
          name = name.to_s
          raise Error, "#{@definition.name}: variant names are snake_case, not #{name.inspect}" unless name.match?(NAME)
          raise Error, "#{@definition.name}: variant #{name} needs a block to run" unless block

          @definition.variants[name] = block
        end

        # :fields, :band, :list, :rubric or :winner (see evals/README.md), or a block
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

      attr_reader :name, :dir, :variants
      attr_accessor :subject, :grader
      attr_writer :watch

      def initialize(name:, dir:)
        @name = name
        @dir = dir
        @grader = 'fields'
        @variants = {}
      end

      # [nil] for an eval with one `call`, else its variant names in the order they were defined.
      def variant_names
        @variants.empty? ? [nil] : @variants.keys
      end

      # The block that runs `variant` (nil: the eval's `call`).
      def subject_for(variant)
        variant ? @variants.fetch(variant) : subject
      end

      def runnable?
        !subject.nil? || @variants.any?
      end

      # The eval's own `watch`, else `watch:` in evals/config.yml (one list for every eval of the app),
      # else DEFAULT_WATCH.
      def watch
        return @watch if @watch

        globs = Array(Eval.config['watch']).map(&:to_s)
        globs.empty? ? DEFAULT_WATCH : globs
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

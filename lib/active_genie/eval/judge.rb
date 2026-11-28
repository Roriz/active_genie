# frozen_string_literal: true

module ActiveGenie
  module Eval
    # The pinned LLM judge from evals/config.yml (`judge: { provider, model }`). It does two jobs:
    #
    # - equivalence: a `fields` gold marked `judge: true` whose deterministic check failed ("is this
    #   answer the same as the reference?"),
    # - rubric: a `rubric` gold, scored 0-100 with ActiveGenie::Scorer against the rubric.
    #
    # Verdicts are appended to evals/judge/<model>.jsonl (commit it): each question is asked once per
    # judge model, and reports read the file instead of calling the model. The judge is only called
    # while `online` (a paid run you confirmed); a verdict that isn't cached yet grades as `unjudged`.
    class Judge
      FUNCTION = {
        name: 'judge_equivalence',
        description: 'Whether the candidate answer is equivalent to the gold reference for the question.',
        parameters: {
          type: 'object',
          properties: {
            match: { type: 'boolean',
                     description: 'true when a careful human would accept the candidate as the reference' },
            reason: { type: 'string', description: 'One sentence explaining the decision.' }
          },
          required: %w[match reason]
        }
      }.freeze

      INSTRUCTIONS = <<~TEXT
        You check one answer against a gold reference. Say whether a careful human expert would accept
        the candidate as giving the same answer to the question as the reference. Ignore wording, order,
        formatting and extra detail that does not change the answer. A candidate that adds a wrong or
        contradicting claim, hedges between answers, or answers a different question does not match.
      TEXT

      Verdict = Struct.new(:match, :score, :reason, keyword_init: true)

      class << self
        attr_writer :current
        attr_accessor :online

        def current
          @current ||= begin
            judge = Eval.config['judge']
            missing = %w[provider model].reject { |key| judge.is_a?(Hash) && judge[key] }
            raise JudgeConfigMissingError, "judge: { #{missing.join(', ')} }" if missing.any?

            new(provider: judge['provider'], model: judge['model'])
          end
        end

        # Whether grading this gold can ask the judge: every rubric row, and a `fields` gold with a
        # `judge: true` field (asked when its check fails).
        def asks?(definition, gold)
          return false if definition.custom_grader?
          return true if definition.grader == 'rubric'

          fields = gold['fields'] if gold.is_a?(Hash)
          fields.is_a?(Hash) && fields.values.any? { |spec| spec.is_a?(Hash) && spec['judge'] }
        end
      end

      attr_reader :model

      # `answerer.call(kind, payload)` returns { 'match' => bool, 'reason' => String } for :equivalence
      # and { 'score' => Numeric, 'reason' => String } for :rubric. Tests pass a fake.
      def initialize(provider:, model:, answerer: nil)
        @model = model
        @answerer = answerer || ApiAnswerer.new(provider:, model:)
        @mutex = Mutex.new
      end

      # Raises when the judge's provider can't be called (no API key, or removed from config.providers).
      # A fake answerer calls no provider, so it has nothing to check.
      def check_provider!
        @answerer.check_provider! if @answerer.respond_to?(:check_provider!)
      end

      def equivalent(question:, reference:, candidate:)
        ask('equivalence', { question:, reference:, candidate: }) do |answer|
          match = answer['match'] if answer.is_a?(Hash)
          [true, false].include?(match) && Verdict.new(match:, reason: answer['reason'].to_s)
        end
      end

      def rubric(rubric:, candidate:)
        ask('rubric', { rubric:, candidate: }) do |answer|
          score = answer['score'] if answer.is_a?(Hash)
          score.is_a?(Numeric) && Verdict.new(score:, reason: answer['reason'].to_s)
        end
      end

      private

      # The cached verdict for this question, else (online only) a new one. `parse` turns the answer
      # into a Verdict, or false when it is malformed; that raises, so the case stays unjudged instead
      # of being cached as a wrong verdict.
      def ask(kind, payload, &parse)
        key = Digest::SHA256.hexdigest(JSON.generate([model, kind, INSTRUCTIONS, payload]))[0, 16]
        cached = @mutex.synchronize { verdicts[key] }
        return parse.call(cached['answer']) if cached
        return nil unless self.class.online

        answer = @answerer.call(kind, payload)
        verdict = parse.call(answer)
        raise MalformedJudgeAnswerError.new(model:, kind:, answer:) unless verdict

        record('key' => key, 'kind' => kind, 'payload' => payload, 'answer' => answer, 'at' => Time.now.utc.iso8601)
        verdict
      end

      def file
        Eval.path('judge', "#{model}.jsonl")
      end

      def verdicts
        @verdicts ||= Store.read_jsonl(file).to_h { |row| [row['key'], row] }
      end

      def record(row)
        @mutex.synchronize do
          verdicts[row['key']] = row
          FileUtils.mkdir_p(File.dirname(file))
          File.open(file, 'a') { |f| f.puts(JSON.generate(row)) }
        end
      end

      # Calls the judge model through ActiveGenie's own provider layer and Scorer.
      class ApiAnswerer
        RUBRIC_JURIES = ['Rubric grader'].freeze

        def initialize(provider:, model:)
          @config = { providers: { default: provider }, llm: { model: } }
        end

        def call(kind, payload)
          kind == 'rubric' ? rubric(payload) : equivalence(payload)
        end

        # The judge's provider comes from evals/config.yml, so a missing key says so (AG-E226), not
        # that the default provider has none (AG-E007).
        def check_provider!
          providers = ActiveGenie.new_configuration(@config).providers
          providers.check_default!
        rescue ProviderWithoutApiKeyError
          raise JudgeProviderWithoutApiKeyError.new(@config.dig(:providers, :default), providers.valid.keys)
        end

        private

        def equivalence(payload)
          require_relative '../providers/unified_provider'
          messages = [{ role: 'system', content: INSTRUCTIONS },
                      { role: 'user', content: JSON.pretty_generate(payload) }]
          response = ActiveGenie::Providers::UnifiedProvider.function_calling(
            messages, FUNCTION, config: ActiveGenie.new_configuration(@config)
          )
          response.is_a?(Hash) ? response.transform_keys(&:to_s) : response
        end

        # One fixed jury: without it the Scorer asks a model to pick juries per question, an extra paid
        # call whose answer changes the verdict. The Scorer reads a missing score as 0, so the score is
        # kept only when the answer carried one; else the answer counts as malformed.
        def rubric(payload)
          result = ActiveGenie::Scorer.call(payload[:candidate], payload[:rubric], juries: RUBRIC_JURIES,
                                                                                   config: @config)
          meta = result.metadata.is_a?(Hash) ? result.metadata.transform_keys(&:to_s) : {}
          { 'score' => (result.data unless meta['final_score'].nil?), 'reason' => result.reasoning.to_s }
        end
      end
    end
  end
end

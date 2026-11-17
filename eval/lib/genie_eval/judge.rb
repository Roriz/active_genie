# frozen_string_literal: true

module GenieEval
  # The pinned LLM judge, used only where a deterministic check fails on a gold field marked
  # `judge: true` (free text, terse normalized references). Its instructions are eval/prompts/judge.md;
  # it calls the judge model in eval/config.json through ActiveGenie's provider layer.
  #
  # Verdicts are appended to eval/judge/<model>.jsonl (committed): each question is judged once per
  # judge model and prompt, and the file is the audit trail for calibrating the judge against human
  # decisions. Reports never call the judge (`online` is false); a missing verdict grades as `unjudged`.
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

    Verdict = Struct.new(:match, :reason, keyword_init: true)

    class << self
      attr_writer :current
      attr_accessor :online

      # The judge model from eval/config.json, called through its provider API.
      def current
        @current ||= begin
          judge = GenieEval.config.fetch('judge')
          new(model: judge.fetch('model'),
              answerer: ApiAnswerer.new(provider: judge.fetch('provider'), model: judge.fetch('model')))
        end
      end
    end

    attr_reader :model

    # `answerer.call(instructions, payload)` returns { 'match' => bool, 'reason' => String }.
    def initialize(model:, answerer:)
      @model = model
      @answerer = answerer
      @mutex = Mutex.new
    end

    def instructions
      @instructions ||= File.read(File.join(ROOT, 'prompts', 'judge.md'))
    end

    # Returns a Verdict, or nil when the judge is offline and the question was never judged.
    def verdict(question:, reference:, candidate:)
      key = key_for(question, reference, candidate)
      cached = @mutex.synchronize { verdicts[key] }
      return Verdict.new(match: cached['match'], reason: cached['reason']) if cached
      return nil unless self.class.online

      payload = JSON.pretty_generate({ question:, reference:, candidate: })
      answer = @answerer.call(instructions, payload)
      row = { 'key' => key, 'question' => question, 'reference' => reference, 'candidate' => candidate,
              'match' => answer['match'] == true, 'reason' => answer['reason'].to_s, 'at' => Time.now.utc.iso8601 }
      record(row)
      Verdict.new(match: row['match'], reason: row['reason'])
    end

    private

    def file
      GenieEval.path('judge', "#{model}.jsonl")
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

    def key_for(question, reference, candidate)
      Digest::SHA256.hexdigest(JSON.generate([model, instructions, question, reference, candidate.to_s]))[0, 16]
    end

    # Calls the judge model through ActiveGenie's provider layer, with its own provider/model config.
    class ApiAnswerer
      def initialize(provider:, model:)
        @config = { providers: { default: provider }, llm: { model: } }
      end

      def call(instructions, payload)
        require File.join(REPO, 'lib', 'active_genie')
        require File.join(REPO, 'lib', 'active_genie', 'providers', 'unified_provider')
        messages = [{ role: 'system', content: instructions }, { role: 'user', content: payload }]
        response = ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages, FUNCTION, config: ActiveGenie.new_configuration(@config)
        )
        response.is_a?(Hash) && response.key?(:data) ? response[:data] : response
      end
    end
  end
end

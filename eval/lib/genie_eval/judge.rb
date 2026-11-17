# frozen_string_literal: true

module GenieEval
  # The pinned LLM judge, used only where no deterministic matcher can decide (free text,
  # synonymous list items). It runs the `eval-judge` Claude Code subagent (.claude/agents/) through
  # the claude-code transport, on the user's Claude login. Verdicts are cached by content, so a
  # question is judged once per judge model and judge prompt.
  class Judge
    SCHEMA = {
      'type' => 'object',
      'properties' => { 'match' => { 'type' => 'boolean' }, 'reason' => { 'type' => 'string' } },
      'required' => %w[match reason],
      'additionalProperties' => false
    }.freeze

    Verdict = Struct.new(:match, :reason, :cached, keyword_init: true)

    def self.default
      judge = GenieEval.config.fetch('judge')
      new(transport: Transports.for(judge['provider'], model: judge['model']))
    end

    def initialize(transport:)
      raise Error, 'the judge needs a local transport (codex or claude-code)' unless transport

      @transport = transport
    end

    def verdict(question:, reference:, candidate:)
      file = cache_file(question, reference, candidate)
      return Verdict.new(**JSON.parse(File.read(file)).transform_keys(&:to_sym), cached: true) if File.exist?(file)

      prompt = JSON.pretty_generate({ question:, reference:, candidate: })
      answer = @transport.structured(prompt:, schema: SCHEMA, agent: 'eval-judge')
      verdict = { 'match' => answer.data['match'] == true, 'reason' => answer.data['reason'].to_s }
      Store.write_json(file, verdict)
      Verdict.new(**verdict.transform_keys(&:to_sym), cached: false)
    end

    private

    # Keyed by the judge model, its prompt, and the three texts.
    def cache_file(question, reference, candidate)
      prompt = Transports::ClaudeCode.agents.fetch('eval-judge', {})['prompt']
      key = Digest::SHA256.hexdigest(JSON.generate([@transport.model, prompt, question, reference, candidate]))
      GenieEval.path('runs', '_judge', @transport.model, "#{key}.json")
    end
  end
end

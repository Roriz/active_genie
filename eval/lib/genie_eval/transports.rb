# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'tmpdir'

module GenieEval
  # Runs models through local CLIs logged in with the user's own subscriptions instead of the
  # provider APIs: `codex` (OpenAI models via `codex exec`) and `claude-code` (Claude models via a
  # Claude Code subagent, `claude -p --agent`). API keys are removed from the child environment so a
  # CLI can never fall back to API billing.
  #
  # The system under test is unchanged: ActiveGenie still builds its own prompts and function schema;
  # only the transport that answers UnifiedProvider.function_calling is swapped. The CLIs expose no
  # logprobs, so modules take their non-logprob path (e.g. the debate judge's own winner field).
  module Transports
    Answer = Struct.new(:data, :usage, keyword_init: true)

    # The ActiveGenie provider each transport stands in for (keeps the library config valid).
    API_PROVIDER = { 'codex' => 'openai', 'claude-code' => 'anthropic' }.freeze

    module_function

    def for(provider, model:)
      return unless transport?(provider)

      { 'codex' => Codex, 'claude-code' => ClaudeCode }.fetch(provider).new(model:)
    end

    def transport?(provider)
      API_PROVIDER.key?(provider)
    end

    # The transport ActiveGenie calls are routed to in this process (nil = the real provider APIs).
    class << self
      attr_accessor :current
    end

    # Renders ActiveGenie's chat messages and function into one prompt for a CLI.
    def render(messages, function)
      parts = messages.map { |m| "### #{m[:role] || m['role']}\n\n#{m[:content] || m['content']}" }
      <<~PROMPT
        #{parts.join("\n\n")}

        ### function

        Answer by filling the function `#{function[:name]}`: #{function[:description]}
        Reply with the JSON object only.
      PROMPT
    end

    class Base
      attr_reader :model

      def initialize(model:, timeout_s: 300)
        @model = model
        @timeout_s = timeout_s
      end

      # Called in place of the provider API. Returns the parsed arguments (string keys).
      def function_calling(messages, function, config:)
        schema = strict(function[:parameters])
        answer = structured(prompt: Transports.render(messages, function), schema:, agent: 'eval-model')
        ActiveGenie.logger.call({ code: :llm_usage, model:, **answer.usage }, config:)
        answer.data
      end

      private

      # Strict like the OpenAI provider (top-level additionalProperties: false). Also drops `min`/`max`,
      # which are not JSON Schema keywords (Scorer::JuryBench uses them): the APIs ignore them, but the
      # CLIs validate schemas and reject the whole call.
      def strict(parameters)
        without_nonstandard(JSON.parse(JSON.generate(parameters))).merge('additionalProperties' => false)
      end

      # Walks schema nodes only: keys inside `properties` are field names and are kept as they are.
      def without_nonstandard(schema)
        return schema unless schema.is_a?(Hash)

        schema.except('min', 'max').to_h do |key, value|
          value = case key
                  when 'properties' then value.transform_values { |s| without_nonstandard(s) }
                  when 'items' then without_nonstandard(value)
                  when 'anyOf', 'oneOf', 'allOf' then value.map { |s| without_nonstandard(s) }
                  else value
                  end
          [key, value]
        end
      end

      # Runs the CLI; on timeout the process is killed, not just abandoned.
      def run(cmd, stdin:, env:, chdir:)
        Open3.popen3(env, *cmd, chdir:) do |input, output, errors, wait|
          readers = [output, errors].map { |io| Thread.new { io.read } }
          input.write(stdin)
          input.close
          unless wait.join(@timeout_s)
            Process.kill('KILL', wait.pid)
            raise Error, "#{cmd.first} timed out after #{@timeout_s}s"
          end

          out, err = readers.map(&:value)
          raise Error, "#{cmd.first} exited #{wait.value.exitstatus}: #{err.lines.last(3).join.strip}" unless wait.value.success?

          out
        end
      end

      def usage(input, output)
        { input_tokens: input.to_i, output_tokens: output.to_i, total_tokens: input.to_i + output.to_i }
      end
    end

    # OpenAI models through `codex exec` on the user's ChatGPT login. Read-only sandbox in an empty
    # directory; the schema is made strict like the OpenAI provider does.
    class Codex < Base
      # Codex has no subagents, so the agent name is ignored: the prompt carries the instructions.
      def structured(prompt:, schema:, **)
        Dir.mktmpdir('genie-eval-codex') do |dir|
          schema_file = File.join(dir, 'schema.json')
          File.write(schema_file, JSON.generate(schema))
          work = File.join(dir, 'work')
          Dir.mkdir(work)
          cmd = ['codex', 'exec', '--ephemeral', '--skip-git-repo-check', '-s', 'read-only', '-C', work,
                 '-m', model, '--output-schema', schema_file, '--json', '--color', 'never', '-']
          parse(run(cmd, stdin: prompt, env: { 'OPENAI_API_KEY' => nil }, chdir: work))
        end
      end

      private

      def parse(jsonl)
        events = jsonl.lines.filter_map do |line|
          JSON.parse(line)
        rescue JSON::ParserError
          nil
        end
        message = events.reverse.find { |e| e.dig('item', 'type') == 'agent_message' }&.dig('item', 'text')
        raise Error, 'codex returned no answer' unless message

        tokens = events.reverse.find { |e| e['type'] == 'turn.completed' }&.fetch('usage', {}) || {}
        Answer.new(data: JSON.parse(message), usage: usage(tokens['input_tokens'], tokens['output_tokens']))
      rescue JSON::ParserError => e
        raise Error, "codex answer is not JSON: #{e.message}"
      end
    end

    # Claude models through a Claude Code subagent (`claude -p --agent`) on the user's Claude login.
    # The subagent prompts live in .claude/agents/ and are passed inline because the call runs in an
    # empty directory; tools that act are disallowed and anything else is denied without asking.
    class ClaudeCode < Base
      AGENTS_DIR = File.join(REPO, '.claude', 'agents')
      DENIED_TOOLS = %w[Bash Edit Write NotebookEdit WebFetch WebSearch Agent Task].freeze

      def structured(prompt:, schema:, agent: 'eval-model')
        Dir.mktmpdir('genie-eval-claude') do |dir|
          cmd = ['claude', '-p', '--agents', JSON.generate(self.class.agents), '--agent', agent, '--model', model,
                 '--no-session-persistence', '--permission-mode', 'dontAsk',
                 '--disallowed-tools', *DENIED_TOOLS, '--output-format', 'json', '--json-schema', JSON.generate(schema)]
          parse(run(cmd, stdin: prompt, env: { 'ANTHROPIC_API_KEY' => nil, 'ANTHROPIC_AUTH_TOKEN' => nil }, chdir: dir))
        end
      end

      # { name => { description, prompt } } from the subagent definitions in .claude/agents/*.md.
      def self.agents
        @agents ||= Dir.glob(File.join(AGENTS_DIR, 'eval-*.md')).to_h do |file|
          _, front, body = File.read(file).split(/^---\s*$/, 3)
          meta = YAML.safe_load(front)
          [meta.fetch('name'), { 'description' => meta.fetch('description'), 'prompt' => body.strip }]
        end
      end

      private

      def parse(out)
        result = JSON.parse(out)
        raise Error, "claude: #{result['result'].to_s[0, 300]}" if result['is_error']

        data = result['structured_output']
        raise Error, 'claude returned no structured output' unless data.is_a?(Hash)

        tokens = result['usage'] || {}
        input = tokens.values_at('input_tokens', 'cache_read_input_tokens', 'cache_creation_input_tokens').sum(&:to_i)
        Answer.new(data:, usage: usage(input, tokens['output_tokens']))
      rescue JSON::ParserError => e
        raise Error, "claude output is not JSON: #{e.message}"
      end
    end

    API_METHOD = :__genie_eval_api_function_calling

    # Wraps UnifiedProvider.function_calling once: when a transport is active it answers instead of
    # the provider API, and the library's own response normalization still runs. Uses an explicit
    # alias rather than prepend + super, which recurses forever once something (e.g. Minitest#stub)
    # aliases the wrapped method.
    def install!
      unified = ActiveGenie::Providers::UnifiedProvider.singleton_class
      return if unified.private_method_defined?(API_METHOD)

      unified.alias_method API_METHOD, :function_calling
      unified.send(:private, API_METHOD)
      unified.define_method(:function_calling) do |messages, function, config: {}, logprobs: false, top_logprobs: 5|
        transport = GenieEval::Transports.current
        return send(API_METHOD, messages, function, config:, logprobs:, top_logprobs:) unless transport

        normalize_response(transport.function_calling(messages, function, config:))
      end
    end
  end
end

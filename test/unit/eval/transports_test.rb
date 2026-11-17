# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../eval/lib/genie_eval'
require_relative '../../../lib/active_genie/providers/unified_provider'

class GenieEvalTransportsTest < Minitest::Test
  Transports = GenieEval::Transports

  # A CLI transport whose subprocess is replaced by a canned answer.
  class FakeCli < Transports::Base
    attr_reader :calls

    def initialize(answer)
      super(model: 'fake-model')
      @answer = answer
      @calls = []
    end

    def structured(prompt:, schema:, agent:)
      @calls << { prompt:, schema:, agent: }
      Transports::Answer.new(data: @answer, usage: { input_tokens: 10, output_tokens: 5, total_tokens: 15 })
    end
  end

  def teardown
    Transports.current = nil
  end

  def route(answer)
    Transports.install!
    Transports.current = FakeCli.new(answer)
  end

  def test_codex_output_is_parsed_from_the_event_stream
    jsonl = <<~JSONL
      {"type":"thread.started"}
      {"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"{\\"winner\\":\\"player_b\\"}"}}
      {"type":"turn.completed","usage":{"input_tokens":16872,"cached_input_tokens":0,"output_tokens":26}}
    JSONL
    answer = Transports::Codex.new(model: 'm').send(:parse, jsonl)

    assert_equal({ 'winner' => 'player_b' }, answer.data)
    assert_equal 16_898, answer.usage[:total_tokens]
  end

  def test_cli_runs_are_killed_on_timeout_and_failures_raise
    cli = Transports::Codex.new(model: 'm', timeout_s: 1)

    assert_equal "hi\n", cli.send(:run, ['cat'], stdin: "hi\n", env: {}, chdir: Dir.tmpdir)
    assert_raises(GenieEval::Error) { cli.send(:run, ['false'], stdin: '', env: {}, chdir: Dir.tmpdir) }

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    error = assert_raises(GenieEval::Error) { cli.send(:run, %w[sleep 30], stdin: '', env: {}, chdir: Dir.tmpdir) }

    assert_match(/timed out after 1s/, error.message)
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 5, 'the process is killed, not waited for'
  end

  def test_claude_structured_output_and_errors
    ok = { 'is_error' => false, 'structured_output' => { 'match' => true },
           'usage' => { 'input_tokens' => 10, 'cache_read_input_tokens' => 90, 'output_tokens' => 4 } }
    answer = Transports::ClaudeCode.new(model: 'm').send(:parse, JSON.generate(ok))

    assert_equal({ 'match' => true }, answer.data)
    assert_equal 100, answer.usage[:input_tokens]

    error = JSON.generate({ 'is_error' => true, 'result' => 'Credit balance is too low' })
    assert_raises(GenieEval::Error) { Transports::ClaudeCode.new(model: 'm').send(:parse, error) }
  end

  def test_subagent_definitions_are_loaded_from_dot_claude_agents
    agents = Transports::ClaudeCode.agents

    assert_equal %w[eval-judge eval-model], agents.keys.sort
    assert_match(/equivalent/i, agents['eval-judge']['prompt'])
  end

  def test_activegenie_calls_are_answered_by_the_transport
    route({ 'impartial_judge_winner' => 'player_b', 'impartial_judge_winner_reasoning' => 'B is better' })
    result = ActiveGenie::Comparator.by_debate('Option A', 'Option B', 'pick the better one')

    assert_equal 'Option B', result.data
    call = Transports.current.calls.first

    assert_equal 'eval-model', call[:agent]
    assert_match(/Option A/, call[:prompt])
    refute call[:schema]['additionalProperties'], 'schema is made strict like the OpenAI provider'
  end

  def test_nonstandard_min_max_keywords_are_dropped_but_fields_named_max_are_kept
    parameters = { type: 'object', properties: {
      score: { type: 'number', min: 0, max: 100 },
      max: { type: 'integer', description: 'a field called max' },
      tags: { type: 'array', items: { type: 'number', min: 1 } }
    } }
    schema = Transports::Codex.new(model: 'm').send(:strict, parameters)

    assert_equal({ 'type' => 'number' }, schema['properties']['score'])
    assert_equal 'integer', schema['properties']['max']['type']
    assert_equal({ 'type' => 'number' }, schema['properties']['tags']['items'])
    refute schema['additionalProperties']
  end

  def test_usage_from_the_cli_reaches_the_log_observers
    route({ 'final_score' => 72 })
    seen = []
    config = { log: { output: ->(_l) {}, observers: [{ observer: ->(log) { seen << log }, scope: {} }] } }
    ActiveGenie::Scorer.by_jury_bench('text', 'criteria', ['Editor'], config:)

    usage = seen.find { |log| log[:code] == :llm_usage }

    assert_equal 15, usage[:total_tokens]
  end

  def test_judge_verdicts_are_cached
    Dir.mktmpdir do |dir|
      GenieEval.root = dir
      cli = FakeCli.new({ 'match' => true, 'reason' => 'same entity' })
      judge = GenieEval::Judge.new(transport: cli)
      args = { question: 'Who is the CEO?', reference: 'Ana Souza', candidate: 'Ana Souza (CEO)' }

      first = judge.verdict(**args)
      second = judge.verdict(**args)

      assert first.match
      refute first.cached
      assert second.cached
      assert_equal 1, cli.calls.size
      assert_equal 'eval-judge', cli.calls.first[:agent]
    ensure
      GenieEval.root = nil
    end
  end
end

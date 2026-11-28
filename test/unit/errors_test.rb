# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../../lib/active_genie/eval'

module ActiveGenie
  class ErrorsTest < Minitest::Test
    ERRORS_DIR = File.expand_path('../../lib/active_genie/errors', __dir__)
    DOCS = File.read(File.expand_path('../../docs/reference/errors.md', __dir__))
    # Roots to rescue, never raised themselves.
    BASES = [ActiveGenie::Error, ActiveGenie::Eval::Error].freeze

    # One way to build each error, as the gem raises it.
    SAMPLES = {
      WithoutAvailableProviderError => -> { WithoutAvailableProviderError.new },
      InvalidProviderError => -> { InvalidProviderError.new('cohere') },
      InvalidModelError => -> { InvalidModelError.new('command-r', %i[openai]) },
      InvalidLogOutputError => -> { InvalidLogOutputError.new('stdout') },
      InvalidLogScopeError => -> { InvalidLogScopeError.new(:llm_usage) },
      CallNotImplementedError => -> { CallNotImplementedError.new(Class.new(BaseModule)) },
      ProviderWithoutApiKeyError => -> { ProviderWithoutApiKeyError.new('anthropic', %i[openai]) },
      DefaultProviderRemovedError => -> { DefaultProviderRemovedError.new('anthropic', %i[openai]) },
      ProviderUnknownError => -> { ProviderUnknownError.new(provider: 'OpenAI', model: '"gpt-5"', status: 401, body: '') },
      ProviderTransientError => lambda {
        ProviderTransientError.new(provider: 'OpenAI', model: '"gpt-5"', status: 429, body: 'slow', max_retries: 3)
      },
      ProviderConnectionError => -> { ProviderConnectionError.new(provider: 'OpenAI', attempts: 4, error: 'timeout') },
      RefusalError => -> { RefusalError.new(provider: 'Anthropic', model: '"claude"', detail: 'cyber') },
      InvalidResponseError => -> { InvalidResponseError.new(provider: 'Google', model: '"gemini"', detail: 'no text') },
      TruncatedResponseError => lambda {
        TruncatedResponseError.new(provider: 'Anthropic', model: '"claude"', detail: 'max_tokens', max_tokens: 16_000)
      },
      Eval::ConfigMissingError => -> { Eval::ConfigMissingError.new('/app/evals/config.yml') },
      Eval::ConfigSyntaxError => -> { Eval::ConfigSyntaxError.new('/app/evals/config.yml', 'did not find key') },
      Eval::DefineOutsideLoadError => -> { Eval::DefineOutsideLoadError.new('router') },
      Eval::EvalNameMismatchError => -> { Eval::EvalNameMismatchError.new(folder: 'router', name: 'other') },
      Eval::UnknownEvalError => -> { Eval::UnknownEvalError.new('ruoter', %w[router]) },
      Eval::InvalidEvalNameError => -> { Eval::InvalidEvalNameError.new('Ticket Router') },
      Eval::InvalidVariantNameError => -> { Eval::InvalidVariantNameError.new('router', 'Fast One') },
      Eval::VariantWithoutBlockError => -> { Eval::VariantWithoutBlockError.new('router', 'fast') },
      Eval::MissingCallBlockError => -> { Eval::MissingCallBlockError.new('router') },
      Eval::UnknownGraderError => -> { Eval::UnknownGraderError.new('router', 'exact') },
      Eval::UnknownCheckError => -> { Eval::UnknownCheckError.new('equals') },
      Eval::UnknownListCheckError => -> { Eval::UnknownListCheckError.new('top_any') },
      Eval::UnknownModeError => -> { Eval::UnknownModeError.new('fast') },
      Eval::MissingGoldError => -> { Eval::MissingGoldError.new('router', 'refund_me') },
      Eval::InvalidJsonlError => -> { Eval::InvalidJsonlError.new('evals/router/datasets.jsonl', 3, 'unexpected token') },
      Eval::JudgeConfigMissingError => -> { Eval::JudgeConfigMissingError.new('judge: { model }') },
      Eval::MalformedJudgeAnswerError => -> { Eval::MalformedJudgeAnswerError.new(model: 'j', kind: 'rubric', answer: {}) },
      Eval::InvalidLabelPassError => -> { Eval::InvalidLabelPassError.new('router', %w[c]) },
      Eval::CustomGraderLabelingError => -> { Eval::CustomGraderLabelingError.new('router') },
      Eval::InvalidWinnerLabelError => -> { Eval::InvalidWinnerLabelError.new('picker', 'A') },
      Eval::InvalidListLabelError => -> { Eval::InvalidListLabelError.new('lister', 'bees') },
      Eval::NoRunToBaselineError => -> { Eval::NoRunToBaselineError.new('router') },
      Eval::IncompleteRunError => -> { Eval::IncompleteRunError.new('router', replicate: 1, count: 2, example: 'a') },
      Eval::UnjudgedRunError => -> { Eval::UnjudgedRunError.new('router', replicate: 1, count: 2) },
      Eval::DirtyWorktreeError => -> { Eval::DirtyWorktreeError.new('router') },
      Eval::JudgeProviderWithoutApiKeyError => -> { Eval::JudgeProviderWithoutApiKeyError.new('anthropic', %i[openai]) }
    }.freeze

    def errors
      ObjectSpace.each_object(Class).select { |klass| klass < ActiveGenie::Error } - BASES
    end

    def test_every_file_in_errors_defines_the_error_it_is_named_after
      files = Dir[File.join(ERRORS_DIR, '**', '*.rb')]
      constants = files.map do |file|
        path = file.delete_prefix("#{ERRORS_DIR}/").delete_suffix('.rb').split('/')
        ['ActiveGenie', *path.map { |part| part.split('_').map(&:capitalize).join }].join('::')
      end

      assert_equal (errors + BASES).map(&:name).sort, constants.sort
    end

    def test_every_error_has_its_own_code
      errors.each { |klass| assert klass.const_defined?(:CODE, false), "#{klass} sets no CODE" }
      codes = errors.map(&:code)

      codes.each { |code| assert_match(/\AAG-E\d{3}\z/, code) }
      assert_equal codes.uniq.size, codes.size, "duplicate codes: #{codes.tally.select { |_, n| n > 1 }.keys}"
    end

    def test_every_error_is_documented_under_its_code
      errors.each do |klass|
        assert_includes DOCS, "{##{klass.code.downcase}}", "#{klass.code} has no anchor in docs/reference/errors.md"
        assert_includes DOCS, "`#{klass.name}`", "#{klass.name} is not in docs/reference/errors.md"
      end
    end

    def test_every_message_says_how_to_fix_it_and_links_its_docs
      assert_equal errors.sort_by(&:name), SAMPLES.keys.sort_by(&:name)

      SAMPLES.each do |klass, build|
        error = build.call

        assert_instance_of klass, error
        assert_equal klass.code, error.code
        assert_match(/\A\S.*\n\nHow to fix:\n  \S/m, error.message)
        assert_match(/\n\nDocs: #{Regexp.escape("https://activegenie.ai/reference/errors##{klass.code.downcase}")}\z/, error.message)
        refute_match(/%<\w+>/, error.message, "#{klass} left a template field unfilled")
      end
    end

    def test_snake_case_suggests_a_valid_eval_name
      assert_equal 'ticket_router', Eval::Error.snake_case('Ticket Router')
      assert_equal 'ticket_router', Eval::Error.snake_case('TicketRouter')
      assert_equal 'ticket_router', Eval::Error.snake_case('42')
    end

    def test_a_log_scope_that_is_not_a_hash_raises
      error = assert_raises(InvalidLogScopeError) { Configuration.new.log.add_observer(scope: :llm_usage) }

      assert_includes error.message, 'given :llm_usage'
    end

    def test_a_log_output_that_is_not_callable_raises
      error = assert_raises(InvalidLogOutputError) { Configuration.new.log.output = 'stdout' }

      assert_includes error.message, 'given "stdout"'
    end

    def test_a_module_without_call_raises
      error = assert_raises(CallNotImplementedError) { Class.new(BaseModule).call }

      assert_includes error.message, 'does not define `call`'
    end
  end
end

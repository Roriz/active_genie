# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require_relative '../../../lib/active_genie/eval'
require_relative 'eval_install_helper'

# active_genie:eval:install and active_genie:eval:new[name] write the starting files of evals/ into a
# throwaway app, and never overwrite one.
class EvalInstallTest < Minitest::Test
  Eval = ActiveGenie::Eval

  def setup
    @app = Dir.mktmpdir
    Eval.reset!
    Eval.app_root = @app
  end

  def teardown
    Eval.app_root = nil
    Eval.reset!
    FileUtils.rm_rf(@app)
    super
  end

  def test_install_writes_the_config_the_guide_and_the_gitignore
    out, = capture_io { EvalInstallTasks.invoke('install') }

    assert_equal "  create  evals/config.yml\n  create  evals/README.md\n  create  evals/.gitignore\n", out
    assert_equal File.read(File.join(ActiveGenieEvalInstall::TEMPLATES, 'gitignore')), File.read(File.join(@app, 'evals', '.gitignore'))
  end

  def test_new_installs_first_and_never_overwrites
    out, = capture_io { EvalInstallTasks.invoke('new', 'ticket_router') }
    eval_rb = File.join(@app, 'evals', 'ticket_router', 'eval.rb')

    assert_match(%r{create  evals/config.yml}, out, 'installs when evals/config.yml is missing')
    assert_match(%r{create  evals/ticket_router/datasets.jsonl}, out)
    assert_match(/ActiveGenie::Eval.define 'ticket_router'/, File.read(eval_rb))
    assert_match(/TicketRouter.new/, File.read(eval_rb), 'the template gets the class name')

    File.write(eval_rb, '# mine')
    out, = capture_io { EvalInstallTasks.invoke('new', 'ticket_router') }

    assert_equal '# mine', File.read(eval_rb)
    assert_equal "  exists  evals/ticket_router/eval.rb\n  exists  evals/ticket_router/datasets.jsonl\n", out
  end

  def test_new_rejects_a_name_that_is_not_snake_case
    _, err = capture_io do
      assert_raises(SystemExit) { EvalInstallTasks.invoke('new', 'Ticket Router') }
    end

    assert_equal "eval names are snake_case, like ticket_router (not \"Ticket Router\")\n", err
    refute_path_exists File.join(@app, 'evals')
  end

  def test_the_new_eval_passes_the_check_once_it_calls_something
    capture_io { EvalInstallTasks.invoke('new', 'ticket_router') }
    check = Eval::Check.new.run

    assert_predicate check, :ok?, check.report
  end
end

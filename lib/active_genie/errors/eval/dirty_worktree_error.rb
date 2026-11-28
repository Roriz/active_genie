# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  module Eval
    # A baseline was saved while the eval's watched files had uncommitted changes.
    class DirtyWorktreeError < Error
      CODE = 'AG-E225'
      MESSAGE = 'The watched files of %<eval>s have uncommitted changes, so a baseline would not match a commit.'
      FIX = <<~FIX
        Commit the changes, then run `rake active_genie:eval:save EVAL=%<eval>s` again, or pass FORCE=1
        to save it anyway.
      FIX

      def initialize(eval_name)
        super(eval: eval_name)
      end
    end
  end
end

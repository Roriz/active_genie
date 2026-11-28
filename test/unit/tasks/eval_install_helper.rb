# frozen_string_literal: true

require 'rake'

# The tasks of lib/tasks/eval_install.rake, loaded once into a Rake application of their own, so a
# test runs them the way an app's `rake` does.
module EvalInstallTasks
  APPLICATION = Rake.with_application do
    load File.expand_path('../../../lib/tasks/eval_install.rake', __dir__)
  end

  module_function

  # rake "active_genie:eval:<name>[args]". Rake runs a task once per application, so re-enable it.
  def invoke(name, *)
    APPLICATION["active_genie:eval:#{name}"].tap(&:reenable).invoke(*)
  end
end

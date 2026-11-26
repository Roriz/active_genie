# frozen_string_literal: true

require 'erb'

module ActiveGenie
  module Eval
    # Writes the starting files into the app. It never overwrites a file that exists: once written,
    # they are the app's to edit.
    module Scaffold
      TEMPLATES = File.join(__dir__, 'templates')
      NAME = /\A[a-z][a-z0-9_]*\z/

      module_function

      # evals/config.yml, evals/README.md and evals/.gitignore.
      def install(io: $stdout)
        write(Eval.path('config.yml'), read('config.yml'), io:)
        write(Eval.path('README.md'), read('README.md'), io:)
        write(Eval.path('.gitignore'), read('gitignore'), io:)
      end

      # evals/<name>/eval.rb and a starting set with example rows.
      def new_eval(name, io: $stdout)
        name = name.to_s
        raise Error, "eval names are snake_case, like ticket_router (not #{name.inspect})" unless name.match?(NAME)

        install(io:) unless File.exist?(Eval.path('config.yml'))
        class_name = name.split('_').map(&:capitalize).join
        write(Eval.path(name, 'eval.rb'), ERB.new(read('eval.rb.erb'), trim_mode: '-').result(binding), io:)
        write(Eval.path(name, 'sets', "#{name}.jsonl"), read('set.jsonl'), io:)
      end

      def read(template)
        File.read(File.join(TEMPLATES, template))
      end

      def write(file, content, io:)
        relative = file.delete_prefix("#{Eval.app_root}/")
        return io.puts("  exists  #{relative}") if File.exist?(file)

        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, content)
        io.puts("  create  #{relative}")
      end
    end
  end
end

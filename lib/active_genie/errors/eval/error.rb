# frozen_string_literal: true

require_relative '../error'

module ActiveGenie
  module Eval
    # The root of the eval engine's errors: a problem in the app's evals/ setup or data. The rake tasks
    # print these without a backtrace.
    class Error < ActiveGenie::Error
      # "Ticket Router" -> "ticket_router", for a fix that shows a valid name.
      def self.snake_case(name)
        snake = name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.gsub(/[^a-z0-9]+/, '_')
        snake = snake.sub(/\A[^a-z]+/, '').delete_suffix('_')
        snake.empty? ? 'ticket_router' : snake
      end
    end
  end
end

# frozen_string_literal: true

module ActiveGenie
  module Config
    class BaseConfig
      def initialize(**args)
        attributes.each do |var|
          send("#{var}=", args[var] || args[var.to_s])
        end
      end

      def attributes
        public_methods(false).grep(/=$/).map { |m| m.to_s.delete('=').to_sym }
      end

      def to_h
        h = {}
        attributes.each do |var|
          h[var.to_sym] = send(var)
        end
        h
      end
    end
  end
end

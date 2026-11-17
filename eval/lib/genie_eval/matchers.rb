# frozen_string_literal: true

require 'date'

module GenieEval
  # Deterministic comparisons between an output value and a gold spec. Strings are compared
  # trimmed, whitespace-collapsed and case-insensitive; numbers numerically.
  module Matchers
    CHECKS = %w[eq one_of regex contains_any contains_all gte lte between near nonempty date].freeze
    DATE_FORMATS = ['%Y-%m-%d', '%m/%d/%Y', '%m/%d/%y', '%B %d, %Y', '%b %d, %Y', '%B %d %Y', '%d %B %Y', '%d %b %Y',
                    '%b. %d, %Y'].freeze

    module_function

    def absent?(value)
      case value
      when nil then true
      when String then value.strip.empty?
      when Array, Hash then value.empty?
      else false
      end
    end

    def normalize(value)
      text = value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value.to_s
      text.strip.downcase.gsub(/\s+/, ' ')
    end

    def number(value)
      return value.to_f if value.is_a?(Numeric)
      return nil unless value.is_a?(String)

      digits = value.delete(',_')[/-?\d+(?:\.\d+)?/]
      digits && Float(digits)
    end

    # Texts to search: each array item, plus (for arrays) the whole list joined.
    def texts(value)
      return [normalize(value)] unless value.is_a?(Array)

      items = value.map { |v| normalize(v) }
      items + [items.join(' | ')]
    end

    def eq?(value, expected)
      if expected.is_a?(Numeric)
        num = number(value)
        !num.nil? && (num - expected).abs < 1e-9
      else
        normalize(value) == normalize(expected)
      end
    end

    def check?(spec, value)
      expected = spec['value']
      case spec['check']
      when 'eq' then eq?(value, expected)
      when 'one_of' then Array(expected).any? { |e| eq?(value, e) }
      when 'regex' then texts(value).any? { |t| Regexp.new(expected, Regexp::IGNORECASE).match?(t) }
      when 'contains_any' then contains_any?(value, expected)
      when 'contains_all' then Array(expected).all? { |sub| texts(value).any? { |t| t.include?(sub.downcase) } }
      when 'gte', 'lte', 'between', 'near' then numeric?(spec, number(value))
      when 'nonempty' then !absent?(value)
      when 'date' then date(value)&.iso8601 == expected
      else raise Error, "unknown check #{spec['check'].inspect}"
      end
    end

    # A calendar date in any common written form ("2014-02-10", "2/10/14", "February 10th, 2014"), else nil.
    def date(value)
      text = value.to_s.strip.sub(/(\d)(?:st|nd|rd|th)\b/, '\1')
      DATE_FORMATS.each do |format|
        parsed = Date.strptime(text, format)
        return parsed if parsed.year >= 100 # "2/10/14" must not match %Y as year 14
      rescue Date::Error
        next
      end
      nil
    end

    def contains_any?(value, substrings)
      subs = Array(substrings).map(&:downcase)
      texts(value).any? { |t| subs.any? { |sub| t.include?(sub) } }
    end

    def numeric?(spec, num)
      return false if num.nil?

      expected = spec['value']
      case spec['check']
      when 'gte' then num >= expected
      when 'lte' then num <= expected
      when 'between' then num.between?(expected[0], expected[1])
      when 'near' then (num - expected).abs <= spec.fetch('delta')
      end
    end
  end
end

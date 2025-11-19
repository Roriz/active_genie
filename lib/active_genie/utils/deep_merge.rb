# frozen_string_literal: true

module ActiveGenie
  module DeepMerge
    module_function

    def call(first_hash, second_hash)
      merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
      first_hash.to_h.merge(second_hash.to_h, &merger)
    end
  end
end

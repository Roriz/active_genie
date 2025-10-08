# frozen_string_literal: true

module ActiveGenie
  module DeepMerge
    module_function

    def call(first_hash, second_hash)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      first_hash.merge(second_hash, &merger)
    end
  end
end

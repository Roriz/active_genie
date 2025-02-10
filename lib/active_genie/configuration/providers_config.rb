module ActiveGenie::Configuration
  class ProvidersConfig
    def initialize
      @all = {}
      @default = nil
    end

    def register(name, provider_class)
      @all ||= {}
      @all[name] = provider_class.new
      define_singleton_method(name) do
        instance_variable_get("@#{name}") || instance_variable_set("@#{name}", @all[name])
      end

      self
    end

    def default
      @default || @all.values.first
    end

    def all
      @all
    end

    def to_h(config = {})
      hash_all = {}
      @all.each do |name, provider|
        hash_all[name] = provider.to_h(config.dig(name) || {})
      end
      hash_all
    end

    private
    attr_writer :default
  end
end

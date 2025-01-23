require 'yaml'

module ActiveGenie
  class Configuration
    attr_accessor :path_to_config

    def initialize
      @path_to_config = File.join(__dir__, 'config', 'gen_ai.yml')
    end

    def values
      return @values if @values

      @values = load_values.transform_keys(&:to_sym)
      @values.each do |key, _value|
        @values[key][:model] = key
        @values[key] = @values[key].transform_keys(&:to_sym)
      end
    end

    private

    def load_values
      return {} unless File.exist?(@path_to_config)

      YAML.load_file(@path_to_config) || {}
    rescue Psych::SyntaxError => e
      warn "ActiveGenie.warning: Config file '#{@path_to_config}' is not a valid YAML file (#{e.message}), using default configuration"
      {}
    end
  end
end
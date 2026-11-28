# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # The network failed on every attempt: the connection was refused, or opening it or reading the
  # answer timed out. `cause` is the last network error.
  class ProviderConnectionError < Error
    CODE = 'AG-E103'
    MESSAGE = 'Could not reach %<provider>s after %<attempts>s attempts: %<error>s'
    FIX = <<~FIX
      Check that this host can reach the provider (proxy, firewall, DNS) and, for a gateway, its
      config.providers.<name>.api_url. A model that answers slowly needs a longer
      config.llm.read_timeout (default 60 seconds); config.llm.open_timeout covers opening the
      connection (default 10 seconds).
    FIX
  end
end

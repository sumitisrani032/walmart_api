# frozen_string_literal: true

require_relative "walmart_api/version"
require_relative "walmart_api/configuration"

module WalmartApi
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end

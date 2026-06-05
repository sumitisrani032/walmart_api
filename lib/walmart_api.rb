# frozen_string_literal: true

require_relative "walmart_api/version"
require_relative "walmart_api/errors"
require_relative "walmart_api/configuration"
require_relative "walmart_api/auth/signature_generator"

module WalmartApi
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

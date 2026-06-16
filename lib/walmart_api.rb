# frozen_string_literal: true

require_relative "walmart_api/version"
require_relative "walmart_api/errors"
require_relative "walmart_api/configuration"
require_relative "walmart_api/auth/signature_generator"
require_relative "walmart_api/auth/token_manager"
require_relative "walmart_api/middleware/authentication"
require_relative "walmart_api/middleware/error_handler"
require_relative "walmart_api/response"
require_relative "walmart_api/paginated_response"
require_relative "walmart_api/resources/base"
require_relative "walmart_api/resources/orders"
require_relative "walmart_api/resources/inventory"
require_relative "walmart_api/resources/items"
require_relative "walmart_api/client"

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

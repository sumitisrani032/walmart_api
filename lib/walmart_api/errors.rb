# frozen_string_literal: true

module WalmartApi
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class ApiError < Error
    attr_reader :status, :body, :correlation_id

    def initialize(status:, body:, correlation_id: nil)
      @status = status
      @body = body
      @correlation_id = correlation_id
      super(build_message)
    end

    private

    def build_message
      return extract_error_details if extract_error_details

      "Walmart API error (HTTP #{status})"
    end

    def extract_error_details
      return unless body.is_a?(Hash)

      errors = body["errors"]
      return unless errors.is_a?(Array) && !errors.empty?

      details = errors.map { |e| e["description"] || e["message"] }.compact.join("; ")
      details.empty? ? nil : details
    end
  end

  class AuthenticationError < ApiError; end
  class AuthorizationError < ApiError; end
  class NotFoundError < ApiError; end
  class ValidationError < ApiError; end

  class RateLimitError < ApiError
    attr_reader :retry_after

    def initialize(status:, body:, correlation_id: nil, retry_after: nil)
      @retry_after = retry_after
      super(status: status, body: body, correlation_id: correlation_id)
    end
  end

  class ServerError < ApiError; end
end

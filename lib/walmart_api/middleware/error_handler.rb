# frozen_string_literal: true

require "json"

module WalmartApi
  module Middleware
    class ErrorHandler < Faraday::Middleware
      CORRELATION_HEADER = "WM_QOS.CORRELATION_ID"
      RETRY_AFTER_HEADER = "Retry-After"

      ERROR_MAP = {
        400 => ValidationError,
        401 => AuthenticationError,
        403 => AuthorizationError,
        404 => NotFoundError,
        429 => RateLimitError
      }.freeze

      def on_complete(env)
        return if env.success?

        raise build_exception(env)
      end

      private

      def build_exception(env)
        status = env.status
        body = parse_body(env.body)
        correlation_id = env.response_headers[CORRELATION_HEADER]
        error_class = error_class_for(status)

        if error_class == RateLimitError
          retry_after = parse_retry_after(env.response_headers[RETRY_AFTER_HEADER])
          error_class.new(status: status, body: body, correlation_id: correlation_id, retry_after: retry_after)
        else
          error_class.new(status: status, body: body, correlation_id: correlation_id)
        end
      end

      def error_class_for(status)
        ERROR_MAP.fetch(status) { status >= 500 ? ServerError : ApiError }
      end

      def parse_body(body)
        return {} if body.nil? || body.to_s.strip.empty?

        JSON.parse(body)
      rescue JSON::ParserError
        { "raw" => body.to_s }
      end

      def parse_retry_after(value)
        return nil if value.nil?

        value.to_i
      end
    end
  end
end

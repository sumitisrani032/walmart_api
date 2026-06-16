# frozen_string_literal: true

require "base64"
require "faraday"
require "securerandom"

module WalmartApi
  module Auth
    class TokenManager
      TOKEN_PATH = "/v3/token"
      DEFAULT_BUFFER_SECONDS = 60
      SERVICE_NAME = "Walmart Marketplace"

      def initialize(configuration, buffer_seconds: DEFAULT_BUFFER_SECONDS)
        @configuration = configuration
        @buffer_seconds = buffer_seconds
        @mutex = Mutex.new
        @access_token = nil
        @expires_at = nil
      end

      def access_token
        return @access_token if token_valid?

        @mutex.synchronize do
          return @access_token if token_valid?

          fetch_token
        end

        @access_token
      end

      private

      def token_valid?
        @access_token && @expires_at && Time.now < @expires_at
      end

      def fetch_token
        response = request_token
        body = response.body

        @access_token = body["access_token"]
        @expires_at = Time.now + body["expires_in"].to_i - @buffer_seconds
      end

      def request_token # rubocop:disable Metrics/AbcSize
        response = connection.post(TOKEN_PATH) do |req|
          req.headers["Authorization"] = "Basic #{encoded_credentials}"
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.headers["Accept"] = "application/json"
          req.headers["WM_SVC.NAME"] = SERVICE_NAME
          req.headers["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid
          req.body = "grant_type=client_credentials"
        end

        handle_error_response(response) unless response.success?

        response
      end

      def handle_error_response(response)
        body = response.body.is_a?(Hash) ? response.body : {}
        error_class = error_class_for(response.status)
        raise error_class.new(status: response.status, body: body)
      end

      def error_class_for(status)
        case status
        when 401 then AuthenticationError
        when 403 then AuthorizationError
        else ServerError
        end
      end

      def encoded_credentials
        Base64.strict_encode64("#{@configuration.client_id}:#{@configuration.client_secret}")
      end

      def connection
        @connection ||= Faraday.new(url: @configuration.base_url) do |f|
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end

# frozen_string_literal: true

require "securerandom"

module WalmartApi
  module Middleware
    class Authentication < Faraday::Middleware
      SERVICE_NAME = "Walmart Marketplace"

      def initialize(app, token_manager:, signature_generator:, configuration:)
        super(app)
        @token_manager = token_manager
        @signature_generator = signature_generator
        @configuration = configuration
      end

      def on_request(env)
        timestamp = generate_timestamp
        headers = build_headers(timestamp)
        env.request_headers.merge!(headers)
      end

      private

      def build_headers(timestamp)
        headers = {
          "WM_SEC.ACCESS_TOKEN" => @token_manager.access_token,
          "WM_SVC.NAME" => SERVICE_NAME,
          "WM_QOS.CORRELATION_ID" => SecureRandom.uuid,
          "WM_SEC.TIMESTAMP" => timestamp,
          "WM_SEC.AUTH_SIGNATURE" => generate_signature(timestamp)
        }
        headers["WM_CONSUMER.CHANNEL.TYPE"] = @configuration.channel_type if @configuration.channel_type
        headers
      end

      def generate_timestamp
        (Time.now.to_f * 1000).to_i.to_s
      end

      def generate_signature(timestamp)
        @signature_generator.sign(
          consumer_id: @configuration.client_id,
          timestamp: timestamp
        )
      end
    end
  end
end
